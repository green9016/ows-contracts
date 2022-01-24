// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
//import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
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
    uint256 public constant BABRONS = 5;
    uint256 public constant HERO = 6;

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
    event HeroMinted(address sender, uint heroType, bytes metadata);

    // The tokenId is the NFTs unique identifier, it's just a number that goes
    // 0, 1, 2, 3, etc.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    UnitsAttributes[] public defaultUnits;
    HeroAttributes[] public defaultHeroes;

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
        uint[] memory heroPower,
        uint[] memory heroOffensiveMultiplier,
        uint[] memory heroDefensiveMultiplier,
        uint[] memory heroResourceProduction
    ) ERC1155("") {
        require(unitsNames.length == unitsImageURIs.length);
        require(unitsAttackPoint.length == unitsDefenseInfantry.length);
        require(unitsAttackPoint.length == unitsDefenseCavalry.length);
        require(unitsAttackPoint.length == unitsSpeed.length);
        require(unitsAttackPoint.length == unitsCarryingCapacity.length);

        require(heroPower.length == heroOffensiveMultiplier.length);
        require(heroPower.length == heroDefensiveMultiplier.length);
        require(heroPower.length == heroResourceProduction.length);

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

        for(uint i = 0; i < heroPower.length; i += 1) {
            defaultHeroes.push(HeroAttributes({
                heroType: i,
                name: unitsNames[i + unitsAttackPoint.length],
                imageURI: unitsImageURIs[i + unitsAttackPoint.length],
                power: heroPower[i],
                offensiveMultiplier: heroOffensiveMultiplier[i],
                defensiveMultiplier: heroDefensiveMultiplier[i],
                resourceProduction: heroResourceProduction[i]
            }));
        }

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

            string memory json = Base64.encode(
                abi.encodePacked(
                    '{"name": "',
                    charAttributes.name,
                    ' -- NFT #: ',
                    Strings.toString(_tokenId),
                    '", "description": "", "image": "',
                    charAttributes.imageURI,
                    '", "attributes": [{ "trait_type": "Attack Point", "value": ', strAttackPoint, '}, ',
                    '{ "trait_type": "Defense against Infantry", "value": ', strDefenseInfantry, '},',
                    '{ "trait_type": "Defense against Cavalry", "value": ', strDefenseCavalry, '},',
                    '{ "trait_type": "Speed", "value": ', strSpeed, '},',
                    '{ "trait_type": "Carrying Capacity", "value": ', strCarryingCapacity, '}',
                    ']}'
                )
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

        string memory json1 = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                heroAttributes.name,
                ' -- NFT #: ',
                Strings.toString(_tokenId),
                '", "description": "", "image": "',
                heroAttributes.imageURI,
                '", "attributes": [{ "trait_type": "Power", "value": ', strPower, '}, ',
                '{ "trait_type": "Offensive Multiplier", "value": ', strOffensiveMultiplier, '},',
                '{ "trait_type": "Defensive Multiplier", "value": ', strDefensiveMultiplier, '},',
                '{ "trait_type": "Resource Production", "value": ', strResourceProduction, '}',
                ']}'
            )
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
        // 10 Spearmen Minting Process
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId, 10, "");
        unitsHolderAttributes[newItemId] = UnitsAttributes({
            unitType : SPEARMEN,
            name : defaultUnits[SPEARMEN].name,
            imageURI : defaultUnits[SPEARMEN].imageURI,
            attackPoint : defaultUnits[SPEARMEN].attackPoint,
            defenseInfantry : defaultUnits[SPEARMEN].defenseInfantry,
            defenseCavalry : defaultUnits[SPEARMEN].defenseCavalry,
            speed : defaultUnits[SPEARMEN].speed,
            carryingCapacity : defaultUnits[SPEARMEN].carryingCapacity
        });
        _tokenIds.increment();
        creators[msg.sender] = newItemId;
        nftTypes[newItemId] = 1;
        emit UnitsMinted(msg.sender, newItemId, SPEARMEN, 10, "");

        // 4 Hussars Minting Process
        newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId, 4, "");
        unitsHolderAttributes[newItemId] = UnitsAttributes({
            unitType : HUSSARS,
            name : defaultUnits[HUSSARS].name,
            imageURI : defaultUnits[HUSSARS].imageURI,
            attackPoint : defaultUnits[HUSSARS].attackPoint,
            defenseInfantry : defaultUnits[HUSSARS].defenseInfantry,
            defenseCavalry : defaultUnits[HUSSARS].defenseCavalry,
            speed : defaultUnits[HUSSARS].speed,
            carryingCapacity : defaultUnits[HUSSARS].carryingCapacity
        });
        creators[msg.sender] = newItemId;
        nftTypes[newItemId] = 1;
        emit UnitsMinted(msg.sender, newItemId, HUSSARS, 4, "");
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
        console.log(ERC1155.balanceOf(msg.sender, _attackerId) * attacker.attackPoint);
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
}
