// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/Base64.sol";
import "./libraries/Math.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/ILayerZeroReceiver.sol";
import "hardhat/console.sol";

contract OmnichainWarsv0 is ERC1155, ILayerZeroReceiver {
    using Math for uint256;

    uint256 public constant LIGHT_INFANTRY = 0;
    uint256 public constant HEAVY_INFANTRY = 1;
    uint256 public constant LIGHT_CAVALRY = 2;
    uint256 public constant HEAVY_CAVALRY = 3;
    uint256 public constant SIEGE_MACHINE = 4;
    uint256 public constant SPECIAL_UNIT = 5;
    uint256 public constant HERO = 0;

    uint8 public constant CROSS_A2B = 1;
    uint8 public constant CROSS_B2A = 2;

    struct UnitsAttributes {
        uint unitType;
        string name;
        string imageURI;
        uint attackPoint;
        uint defenseInfantry;
        uint defenseCavalry;
        uint speed;
        uint carryingCapacity;
    }

    struct HeroAttributes {
        uint heroType;
        string name;
        string imageURI;
        uint power;
        uint offensiveMultiplier;
        uint defensiveMultiplier;
        uint resourceProduction;
    }

    event UnitsMinted(address sender, uint newItemId, uint unitType, uint supply, bytes metadata);
    event HeroMinted(address sender, uint newItemId, uint heroType, bytes metadata);

    // The tokenId is the NFTs unique identifier, it's just a number that goes
    // 0, 1, 2, 3, etc.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    UnitsAttributes[] public defaultUnits;
    HeroAttributes public defaultHeroes;
    
    // LayerZero endpoint
    ILayerZeroEndpoint public endpoint;

    mapping(uint256 => UnitsAttributes) public unitsHolderAttributes;
    mapping(uint256 => HeroAttributes) public heroHolderAttributes;
    // TokenID => Token Count
    mapping(uint256 => uint) public unitsCount;
    // TokenID => Unit or Hero
    mapping(uint256 => uint) public nftTypes;
    // Address => TokenID
    mapping(address => uint) public creators;
    // TokenID => Address
    mapping(uint256 => address) public tokenOwner;

    constructor(
        string[] memory unitsNames,
        string[] memory unitsImageURIs,
        uint[] memory unitsAttackPoint,
        uint[] memory unitsDefenseInfantry,
        uint[] memory unitsDefenseCavalry,
        uint[] memory unitsSpeed,
        uint[] memory unitsCarryingCapacity,
        uint heroPower,
        uint heroOffensiveMultiplier,
        uint heroDefensiveMultiplier,
        uint heroResourceProduction
    ) ERC1155("Omni Wars") {
        require(unitsNames.length == unitsImageURIs.length);
        require(unitsAttackPoint.length == unitsDefenseInfantry.length);
        require(unitsAttackPoint.length == unitsDefenseCavalry.length);
        require(unitsAttackPoint.length == unitsSpeed.length);
        require(unitsAttackPoint.length == unitsCarryingCapacity.length);

        for(uint i = 0; i < unitsAttackPoint.length; i += 1) {
            defaultUnits.push(UnitsAttributes({
                unitType: i,
                name: unitsNames[i],
                imageURI: unitsImageURIs[i],
                attackPoint: unitsAttackPoint[i],
                defenseInfantry: unitsDefenseInfantry[i],
                defenseCavalry: unitsDefenseCavalry[i],
                speed: unitsSpeed[i],
                carryingCapacity: unitsCarryingCapacity[i]
            }));
        }

        defaultHeroes = HeroAttributes({
            heroType: 0,
            name: unitsNames[unitsNames.length - 1],
            imageURI: unitsImageURIs[unitsImageURIs.length - 1],
            power: heroPower,
            offensiveMultiplier: heroOffensiveMultiplier,
            defensiveMultiplier: heroDefensiveMultiplier,
            resourceProduction: heroResourceProduction
        });

        // I increment _tokenIds here so that my first NFT has an ID of 1.
        _tokenIds.increment();
    }

    function getAllDefaultCharacters() public view returns (UnitsAttributes[] memory) {
        return defaultUnits;
    }

    /*function mintCharacterNFT(uint _unitType, uint _amount) external {
        require(_unitType <= 6, "Invalid Unit Type");

        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId, _amount, "");

        if (_unitType >= 0 && _unitType <= 5) {
            unitsHolderAttributes[newItemId] = UnitsAttributes({
                unitType : _unitType,
                name : defaultUnits[_unitType].name,
                imageURI : defaultUnits[_unitType].imageURI,
                attackPoint : defaultUnits[_unitType].attackPoint,
                defenseInfantry : defaultUnits[_unitType].defenseInfantry,
                defenseCavalry : defaultUnits[_unitType].defenseCavalry,
                speed : defaultUnits[_unitType].speed,
                carryingCapacity : defaultUnits[_unitType].carryingCapacity
            });
        } else if (_unitType > 5) {
            heroHolderAttributes[newItemId] = HeroAttributes({
                heroType: _unitType,
                name: defaultHeroes[_unitType].name,
                imageURI: defaultHeroes[_unitType].imageURI,
                power: defaultHeroes[_unitType].power,
                offensiveMultiplier: defaultHeroes[_unitType].offensiveMultiplier,
                defensiveMultiplier: defaultHeroes[_unitType].defensiveMultiplier,
                resourceProduction: defaultHeroes[_unitType].resourceProduction
            });
        }

        creators[msg.sender] = newItemId;

        // Increment the tokenId for the next person that uses it.
        _tokenIds.increment();
        nftTypes[newItemId] = 1;

        emit UnitsMinted(msg.sender, newItemId, _unitType, _amount, "");
    }*/

    function uri(uint256 _tokenId) public override view returns (string memory) {
        if (isUnitOrHero(_tokenId)) {
            UnitsAttributes memory charAttributes = unitsHolderAttributes[_tokenId];

            string memory strAttackPoint = Strings.toString(charAttributes.attackPoint);
            string memory strDefenseInfantry = Strings.toString(charAttributes.defenseInfantry);
            string memory strDefenseCavalry = Strings.toString(charAttributes.defenseCavalry);
            string memory strSpeed = Strings.toString(charAttributes.speed);
            string memory strCarryingCapacity = Strings.toString(charAttributes.carryingCapacity);

            bytes memory encoded1 = abi.encodePacked(
                '{"name": "',
                charAttributes.name,
                ' -- NFT #: ',
                Strings.toString(charAttributes.unitType),
                '", "description": "", "image": "',
                charAttributes.imageURI,
                '", "attributes": [{ "trait_type": "Attack Point", "value": ', strAttackPoint, '}, ',
                '{ "trait_type": "Defense against Infantry", "value": ', strDefenseInfantry, '},'
            );

            bytes memory encoded2 = abi.encodePacked(
                '{ "trait_type": "Defense against Cavalry", "value": ', strDefenseCavalry, '},',
                '{ "trait_type": "Speed", "value": ', strSpeed, '},',
                '{ "trait_type": "Carrying Capacity", "value": ', strCarryingCapacity, '}',
                ']}'
            );

            string memory json = Base64.encode(
                abi.encodePacked(string(encoded1), string(encoded2))
            );

            string memory output = string(
                abi.encodePacked("data:application/json;base64,", json)
            );

            return output;
        }
        HeroAttributes memory heroAttributes = heroHolderAttributes[_tokenId];

        string memory strPower = Strings.toString(heroAttributes.power);
        string memory strOffensiveMultiplier = Strings.toString(heroAttributes.offensiveMultiplier);
        string memory strDefensiveMultiplier = Strings.toString(heroAttributes.defensiveMultiplier);
        string memory strResourceProduction = Strings.toString(heroAttributes.resourceProduction);

        bytes memory encoded3 = abi.encodePacked(
            '{"name": "',
            heroAttributes.name,
            ' -- NFT #: ',
            Strings.toString(heroAttributes.heroType),
            '", "description": "", "image": "',
            heroAttributes.imageURI,
            '", "attributes": [{ "trait_type": "Power", "value": ', strPower, '}, ',
            '{ "trait_type": "Offensive Multiplier", "value": ', strOffensiveMultiplier, '},'
        );
        bytes memory encoded4 = abi.encodePacked(
            '{ "trait_type": "Defensive Multiplier", "value": ', strDefensiveMultiplier, '},',
            '{ "trait_type": "Resource Production", "value": ', strResourceProduction, '}',
            ']}'
        );

        string memory json1 = Base64.encode(
            abi.encodePacked(string(encoded3), string(encoded4))
        );

        string memory output1 = string(
            abi.encodePacked("data:application/json;base64,", json1)
        );

        return output1;
    }

    /// @notice This function will be called when the attacker attacks defenders. It's only capture attack mode
    /// @dev x = 100% · (looser points / winner points)^K (if N < 1000, K = 1.5)
    /// @param _attackerIds, _defenderIds
    function combat(uint256[] memory _attackerIds, uint256[] memory _defenderIds) external {
        for (uint i = 0; i < _attackerIds.length; i++) {
            require(ERC1155.balanceOf(msg.sender, _attackerIds[i]) > 0, "");
        }
        for (uint i = 0; i < _defenderIds.length; i++) {
            require(nftTypes[_defenderIds[i]] > 0, "");
        }

        uint256 attackerPoints = _sumAttackPoints(_attackerIds);
        uint256 defenderPoints = _sumDefenderPoints(_defenderIds, attackerPoints);
        console.log(attackerPoints);
        console.log(defenderPoints);

        if (attackerPoints > defenderPoints) {
            /// x = 100% · (looser points / winner points) ^ K => K = 1.5
            uint losePoint = 100 * Math.sqrtu((100 * defenderPoints / attackerPoints) ** 3);
            for (uint i = 0; i < _attackerIds.length; i++) {
                uint balance = ERC1155.balanceOf(msg.sender, _attackerIds[i]);
                _burn(msg.sender, _attackerIds[i], (balance - balance * losePoint / 100000));
            }
            for (uint i = 0; i < _defenderIds.length; i++) {
                _burn(tokenOwner[_defenderIds[i]], _defenderIds[i], ERC1155.balanceOf(tokenOwner[_defenderIds[i]], _defenderIds[i]));
            }
        } else if (attackerPoints == defenderPoints) {
            console.log("draw");
        } else {
            console.log("lose");
            /// x = 100% · (looser points / winner points) ^ K => K = 1.5
            uint losePoint = 100 * Math.sqrtu((100 * attackerPoints / defenderPoints) ** 3);
            for (uint i = 0; i < _defenderIds.length; i++) {
                uint balance = ERC1155.balanceOf(tokenOwner[_defenderIds[i]], _defenderIds[i]);
                _burn(tokenOwner[_defenderIds[i]], _defenderIds[i], (balance - balance * losePoint / 100000));
            }
            for (uint i = 0; i < _attackerIds.length; i++) {
                _burn(tokenOwner[_attackerIds[i]], _attackerIds[i], ERC1155.balanceOf(tokenOwner[_attackerIds[i]], _attackerIds[i]));
            }
        }
    }

    function mint() external {
        // 10 Spearmen & 4 Hussars Minting Process
        _mintUnit(LIGHT_INFANTRY, 10);
        _mintUnit(LIGHT_CAVALRY, 4);
        // 1 hero Minting Process
        _mintHero();
    }

    function getAllTokens(address account) public view returns (uint256[] memory) {
        uint256 numTokens = 0;
        uint currentItemId = _tokenIds.current();
        for (uint i = 0; i <= currentItemId; i++) {
            if (ERC1155.balanceOf(account, i) > 0) {
                numTokens++;
            }
        }

        uint256[] memory ret = new uint256[](numTokens);
        uint256 counter = 0;
        for (uint i = 0; i <= currentItemId; i ++) {
            if (ERC1155.balanceOf(account, i) > 0) {
                ret[counter] = i;
                counter ++;
            }
        }
        return ret;
    }

    function isUnitOrHero(uint _tokenId) internal view returns (bool) {
        return nftTypes[_tokenId] == 1;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /// @notice This function will get all attack points of your army get summed up
    /// @dev a = (number of infantry * infantry attack) + (number of cavalry * cavalry attack)
    /// @param _attackerIds Ids
    /// @return sum of attack points
    function _sumAttackPoints(uint[] memory _attackerIds) internal view returns (uint256) {
        uint attackerPoint;
        for (uint i = 0; i < _attackerIds.length; i ++) {
            UnitsAttributes memory attacker = unitsHolderAttributes[_attackerIds[i]];
            attackerPoint += unitsCount[_attackerIds[i]] * attacker.attackPoint;
            /*if (attacker.unitType == LIGHT_INFANTRY || attacker.unitType == HEAVY_INFANTRY) {

            } else if (attacker.unitType == LIGHT_CAVALRY || attacker.unitType == HEAVY_CAVALRY) {
                attackerPoint += ERC1155.balanceOf(msg.sender, _attackerIds[i]) * attacker.attackPoint;
            }*/
        }
        return attackerPoint;
    }

    /// @title This function calculates sum of defense points
    /// @dev  itc = (number of infantry * infantry attack)/(a)
    //            di = number of troops * defense against infantry
    //            dc = number of troops * defense against cavalry
    //            d = di*itc + dc*(1-itc)
    /// @param _defenderIds, _sumAttackerPoints
    /// @return sum of defense points
    function _sumDefenderPoints(uint[] memory _defenderIds, uint _sumAttackerPoints) internal view returns (uint256) {
        uint defenderSum = 0;

        for (uint i = 0; i < _defenderIds.length; i++) {
            UnitsAttributes memory defender = unitsHolderAttributes[_defenderIds[i]];
            uint attackPointOfDefender = unitsCount[_defenderIds[i]] * defender.attackPoint;
            if (defender.unitType == LIGHT_INFANTRY || defender.unitType == HEAVY_INFANTRY) {
                defenderSum += attackPointOfDefender * unitsCount[_defenderIds[i]] * defender.defenseInfantry / _sumAttackerPoints;
            } else if (defender.unitType == LIGHT_CAVALRY || defender.unitType == HEAVY_CAVALRY) {
                defenderSum += attackPointOfDefender * unitsCount[_defenderIds[i]] * defender.defenseCavalry / _sumAttackerPoints;
            }
        }

        return defenderSum;
    }

    function _mintUnit(uint _unitType, uint _amount) internal {
        uint newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId, _amount, "");
        unitsHolderAttributes[newItemId] = UnitsAttributes({
            unitType : _unitType,
            name : defaultUnits[_unitType].name,
            imageURI : defaultUnits[_unitType].imageURI,
            attackPoint : defaultUnits[_unitType].attackPoint,
            defenseInfantry : defaultUnits[_unitType].defenseInfantry,
            defenseCavalry : defaultUnits[_unitType].defenseCavalry,
            speed : defaultUnits[_unitType].speed,
            carryingCapacity : defaultUnits[_unitType].carryingCapacity
        });
        _tokenIds.increment();
        creators[msg.sender] = newItemId;
        nftTypes[newItemId] = 1;
        unitsCount[newItemId] = _amount;
        tokenOwner[newItemId] = msg.sender;
        emit UnitsMinted(msg.sender, newItemId, _unitType, _amount, "");
    }

    function _mintHero() internal {
        uint newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId, 1, "");
        heroHolderAttributes[newItemId] = HeroAttributes({
            heroType: HERO,
            name: defaultHeroes.name,
            imageURI: defaultHeroes.imageURI,
            power: defaultHeroes.power,
            offensiveMultiplier: defaultHeroes.offensiveMultiplier,
            defensiveMultiplier: defaultHeroes.defensiveMultiplier,
            resourceProduction: defaultHeroes.resourceProduction
        });
        _tokenIds.increment();
        creators[msg.sender] = newItemId;
        nftTypes[newItemId] = 2;
        unitsCount[newItemId] = 1;
        tokenOwner[newItemId] = msg.sender;
        emit HeroMinted(msg.sender, newItemId, HERO, "");
    }

    /// @notice combat cross-chain. attackers on chain A attack the defenders on chain B.
    ///     1. on chain A sends total attack power and infantry-to-cavalry ratio to on chain B.
    ///     2. on chain B calculates the total defense power based on that data and sends it back to on chain A
    ///     3. on chain B applies losses (burns troops) in accordance to the combat formula (same combat).
    ///     4. on chain A applies losses (burns troops) in accordance to the combat formula
    function combatCrossChain(
        uint256[] memory _attackerIds, 
        uint16 _defenderChainId, 
        bytes calldata _defenderContractAddress,
        uint256[] memory _defenderIds
    ) external {
        require (address(endpoint) != address(0), "LayerZero endpoint should be set.");

        for (uint i = 0; i < _attackerIds.length; i++) {
            require(ERC1155.balanceOf(msg.sender, _attackerIds[i]) > 0, "");
        }
        // for (uint i = 0; i < _defenderIds.length; i++) {
        //     require(nftTypes[_defenderIds[i]] > 0, "");
        // }

        uint256 attackerPoints = _sumAttackPoints(_attackerIds);

        // send chain A to chain B
        console.log("attack pts:", attackerPoints);
        bytes memory payload = abi.encode(CROSS_A2B, attackerPoints, _attackerIds, _defenderIds);
        console.log("payload");
        (uint nativeFee, uint zroFee) = endpoint.estimateFees(_defenderChainId, address(this), payload, false, bytes(""));
        console.log("message fee:", nativeFee);
        endpoint.send {value: nativeFee} (
            _defenderChainId,
            _defenderContractAddress,
            payload,
            payable(msg.sender),
            address(0x0),
            bytes("")
        );
        console.log("sent");
    }

    function updateAttacker(uint256 _attackerPoints, uint256 _defenderPoints, uint256[] memory _attackerIds) internal {
        // this should be called on chain A
        if (_attackerPoints > _defenderPoints) {
            console.log("won");

            uint losePoint = 100 * Math.sqrtu((100 * _defenderPoints / _attackerPoints) ** 3);

            console.log("updateAttacker pts:", _attackerPoints, _defenderPoints, losePoint);
            for (uint i = 0; i < _attackerIds.length; i++) {
                uint balance = ERC1155.balanceOf(tokenOwner[_attackerIds[i]], _attackerIds[i]);
                _burn(tokenOwner[_attackerIds[i]], _attackerIds[i], (balance - balance * losePoint / 100000));
            }
        } else {
            console.log("lose");

            for (uint i = 0; i < _attackerIds.length; i++) {
                uint balance = ERC1155.balanceOf(tokenOwner[_attackerIds[i]], _attackerIds[i]);
                _burn(tokenOwner[_attackerIds[i]], _attackerIds[i], balance);
            }
        }
    }

    function updateDefender(uint256 _attackerPoints, uint256 _defenderPoints, uint256[] memory _defenderIds) internal {
        // this should be called on chain B
        if (_attackerPoints > _defenderPoints) {
            console.log("won");

            console.log("updateDefender pts:", _attackerPoints, _defenderPoints);
            for (uint i = 0; i < _defenderIds.length; i++) {
                uint balance = ERC1155.balanceOf(tokenOwner[_defenderIds[i]], _defenderIds[i]);
                _burn(tokenOwner[_defenderIds[i]], _defenderIds[i], balance);
            }
        } else {
            console.log("lose");

            uint losePoint = 100 * Math.sqrtu((100 * _attackerPoints / _defenderPoints) ** 3);

            for (uint i = 0; i < _defenderIds.length; i++) {
                uint balance = ERC1155.balanceOf(tokenOwner[_defenderIds[i]], _defenderIds[i]);
                _burn(tokenOwner[_defenderIds[i]], _defenderIds[i], (balance - balance * losePoint / 100000));
            }
        }
    }
    
    // set LayerZeroEndpoint
    function setLayerZeroEndpoint(address _endpoint) external {
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    // LayerZero receiver
    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) override external {
        require (msg.sender == address(endpoint), "Invalid LayerZero Reciver call.");

        // // extract src address from bytes memory
        // address srcAddress;
        // assembly {
        //     srcAddress := mload(add(_srcAddress, 20))
        // }
        // decode payload to get msgType
        (uint16 msgType) = abi.decode(_payload, (uint16));
        console.log("lzReceive", msgType);

        require (msgType == CROSS_A2B || msgType == CROSS_B2A, "Invalid Omniwars Cross Message Type");
        
        if (msgType == CROSS_A2B) {
            
            console.log("lzReceive: A2B");
            // decode payload body
            (
                uint16 _msgType, // already loaded
                uint256 attackerPoints, 
                uint256[] memory attackerIds,
                uint256[] memory defenderIds
            ) = abi.decode(_payload, (uint16, uint256, uint256[], uint256[]));

            uint256 defenderPoints = _sumDefenderPoints(defenderIds, attackerPoints);

            if (attackerPoints == defenderPoints) {
                console.log("draw");
            } else {
                updateDefender(attackerPoints, defenderPoints, defenderIds);
                
                // send chain B to chain A
                bytes memory payload = abi.encode(CROSS_B2A, attackerPoints, defenderPoints, attackerIds, defenderIds);
                (uint nativeFee, uint zroFee) = endpoint.estimateFees(_srcChainId, address(this), payload, false, bytes(""));
                endpoint.send {value: nativeFee} (
                    _srcChainId,
                    _srcAddress,
                    payload,
                    payable(msg.sender),
                    address(0x0),
                    bytes("")
                );
            }
        }
        else if (msgType == CROSS_B2A) {
            console.log("lzReceive: B2A");
            // decode payload body
            (
                uint16 _msgType, // already loaded
                uint256 attackerPoints, 
                uint256 defenderPoints, 
                uint256[] memory attackerIds
            ) = abi.decode(_payload, (uint16, uint256, uint256, uint256[]));

            if (attackerPoints == defenderPoints) {
                console.log("draw");
            } else {
                updateAttacker(attackerPoints, defenderPoints, attackerIds);
            }
        }
    }
}
