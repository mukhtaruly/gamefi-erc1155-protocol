// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GameToken} from "../src/GameToken.sol";

contract GameTokenTest is Test {
    GameToken token;

    address player = address(1);

    function setUp() public {
        token = new GameToken();
    }

    function testTransfer() public {
        token.transfer(player, 100 ether);

        assertEq(token.balanceOf(player), 100 ether);
    }

    function testDelegation() public {
        token.transfer(player, 100 ether);

        vm.prank(player);

        token.delegate(player);

        assertEq(token.getVotes(player), 100 ether);
    }

    function testOwnerMintAndPermitNonce() public {
        token.mint(player, 50 ether);

        assertEq(token.balanceOf(player), 50 ether);
        assertEq(token.nonces(player), 0);
    }
}
