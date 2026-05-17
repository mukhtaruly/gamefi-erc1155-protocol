// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

contract VerifyProtocol is Script {
    function run() external view {
        string memory chain = vm.envOr("VERIFY_CHAIN", string("base-sepolia"));
        address contractAddress = vm.envAddress("VERIFY_CONTRACT");
        string memory contractPath = vm.envString("VERIFY_CONTRACT_PATH");

        string[] memory command = new string[](7);
        command[0] = "forge";
        command[1] = "verify-contract";
        command[2] = "--chain";
        command[3] = chain;
        command[4] = vm.toString(contractAddress);
        command[5] = contractPath;
        command[6] = "--watch";

        string[] memory rendered = command;
        rendered;
    }
}
