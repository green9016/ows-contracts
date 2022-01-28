// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/Base64.sol";
import "hardhat/console.sol";

contract OmnichainWarsv0 is ERC1155 {

    uint256 public constant SPEARMEN = 0;
    uint256 public constant SWORDSMEN = 1;
    uint256 public constant HUSSARS = 2;
    uint256 public constant HOLY_KNIGHTS = 3;
    uint256 public constant RAMS = 4;
    uint256 public constant BARONS = 5;
    uint256 public constant HERO = 0;

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

    mapping(uint256 => UnitsAttributes) public unitsHolderAttributes;
    mapping(uint256 => HeroAttributes) public heroHolderAttributes;
    mapping(uint256 => uint) public nftTypes;
    mapping(address => uint) public creators;

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
    ) ERC1155("") {
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
                Strings.toString(_tokenId),
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
            Strings.toString(_tokenId),
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

    function combat(uint256 _attackerId, uint256 _defenderId) external {
        require(ERC1155.balanceOf(msg.sender, _attackerId) > 0, "");
        require(nftTypes[_defenderId] > 0);

        if (isUnitOrHero(_attackerId) && isUnitOrHero(_defenderId)) {
            uint256 attackerPoints = _sumAttackPoints(_attackerId);
            uint256 defenderPoints = _sumDefenderPoints(_defenderId, attackerPoints);
            console.log(attackerPoints);
            console.log(defenderPoints);
            if (attackerPoints > defenderPoints) {
                console.log("win");
            } else if (attackerPoints == defenderPoints) {
                console.log("draw");
            } else {
                console.log("lose");
            }
        }
    }

    function mint() external {
        // 10 Spearmen & 4 Hussars Minting Process
        _mintUnit(SPEARMEN, 10);
        _mintUnit(HUSSARS, 4);
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

    function _sumAttackPoints(uint _attackerId) internal view returns (uint256) {
        UnitsAttributes memory attacker = unitsHolderAttributes[_attackerId];
        return ERC1155.balanceOf(msg.sender, _attackerId) * attacker.attackPoint;
    }

    function _sumDefenderPoints(uint _defenderId, uint _sumAttackerPoints) internal view returns (uint256) {
        /// @notice This function calculates sum of defense points
        /// @formula  itc = (number of infantry * infantry attack)/(a)
        //            di = number of troops * defense against infantry
        //            dc = number of troops * defense against cavalry
        //            d = di*itc + dc*(1-itc)
        /// @param _defenderId, _sumAttackerPoints
        /// @return sum Of defense points
        UnitsAttributes memory defender = unitsHolderAttributes[_defenderId];
        uint defenderSum = 0;
        uint attackPointOfDefender = ERC1155.balanceOf(msg.sender, _defenderId) * defender.attackPoint;
        if (defender.unitType == SPEARMEN || defender.unitType == SWORDSMEN) {
            defenderSum += attackPointOfDefender * ERC1155.balanceOf(msg.sender, _defenderId) * defender.defenseInfantry / _sumAttackerPoints;
        } else if (defender.unitType == HUSSARS || defender.unitType == HOLY_KNIGHTS) {
            defenderSum += attackPointOfDefender * ERC1155.balanceOf(msg.sender, _defenderId) * defender.defenseCavalry / _sumAttackerPoints;
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
        emit HeroMinted(msg.sender, newItemId, HERO, "");
    }
}
