// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {CraftingRules} from "./CraftingRules.sol";
import {ResourceAMM} from "./ResourceAMM.sol";

/// @title ProtocolFactory
/// @notice CREATE2 factory for deterministic AMM and UUPS proxy deployments.
contract ProtocolFactory is AccessControl {
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

    event AMMDeployed(address indexed amm, address indexed tokenA, address indexed tokenB, bytes32 salt);
    event CraftingRulesProxyDeployed(address indexed proxy, address indexed implementation, bytes32 indexed salt);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DEPLOYER_ROLE, admin);
    }

    function deployAMM(address tokenA, address tokenB, bytes32 salt)
        external
        onlyRole(DEPLOYER_ROLE)
        returns (ResourceAMM amm)
    {
        amm = new ResourceAMM{salt: salt}(tokenA, tokenB);

        emit AMMDeployed(address(amm), tokenA, tokenB, salt);
    }

    function deployCraftingRulesProxy(bytes32 salt, address admin)
        external
        onlyRole(DEPLOYER_ROLE)
        returns (address proxy)
    {
        CraftingRules implementation = new CraftingRules();
        bytes memory data = abi.encodeCall(CraftingRules.initialize, (admin));
        proxy = address(new ERC1967Proxy{salt: salt}(address(implementation), data));

        emit CraftingRulesProxyDeployed(proxy, address(implementation), salt);
    }

    function predictAMM(address tokenA, address tokenB, bytes32 salt) external view returns (address) {
        // slither-disable-next-line too-many-digits
        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(ResourceAMM).creationCode, abi.encode(tokenA, tokenB)));

        return _predict(salt, bytecodeHash);
    }

    function _predict(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        bytes32 digest = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash));

        return address(uint160(uint256(digest)));
    }
}
