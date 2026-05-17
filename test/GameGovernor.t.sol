// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {GameToken} from "../src/GameToken.sol";
import {GameGovernor} from "../src/GameGovernor.sol";

import {TimelockController} from
    "@openzeppelin/contracts/governance/TimelockController.sol";

contract GameGovernorTest is Test {
    GameToken token;
    GameGovernor governor;
    TimelockController timelock;

    address voter1 = address(1);
    address voter2 = address(2);

    uint256 constant INITIAL_SUPPLY =
        1_000_000 ether;

    function setUp() public {
        token = new GameToken();

        // proposer needs delegated voting power
        token.delegate(address(this));

        address[] memory proposers =
            new address[](1);

        proposers[0] = address(this);

        address[] memory executors =
            new address[](1);

        executors[0] = address(0);

        timelock =
            new TimelockController(
                2 days,
                proposers,
                executors,
                address(this)
            );

        governor =
            new GameGovernor(
                token,
                timelock
            );

        // governor roles
        bytes32 proposerRole =
            timelock.PROPOSER_ROLE();

        bytes32 executorRole =
            timelock.EXECUTOR_ROLE();

        bytes32 cancellerRole =
            timelock.CANCELLER_ROLE();

        timelock.grantRole(
            proposerRole,
            address(governor)
        );

        timelock.grantRole(
            executorRole,
            address(governor)
        );

        timelock.grantRole(
            cancellerRole,
            address(governor)
        );

        // governance owns token
        token.transferOwnership(
            address(timelock)
        );

        token.transfer(
            voter1,
            100_000 ether
        );

        token.transfer(
            voter2,
            100_000 ether
        );

        vm.prank(voter1);
        token.delegate(voter1);

        vm.prank(voter2);
        token.delegate(voter2);

        // checkpoint snapshots
        vm.roll(block.number + 1);
    }

    function testProposalLifecycleQueueAndExecute()
        public
    {
        address target = address(token);

        uint256 value = 0;

        bytes memory data =
            abi.encodeWithSignature(
                "mint(address,uint256)",
                voter1,
                100 ether
            );

        string memory description =
            "Mint rewards";

        address[] memory targets =
            new address[](1);

        targets[0] = target;

        uint256[] memory values =
            new uint256[](1);

        values[0] = value;

        bytes[] memory calldatas =
            new bytes[](1);

        calldatas[0] = data;

        uint256 proposalId =
            governor.propose(
                targets,
                values,
                calldatas,
                description
            );

        vm.roll(
            block.number +
            governor.votingDelay() +
            1
        );

        vm.prank(voter1);

        governor.castVote(
            proposalId,
            1
        );

        vm.prank(voter2);

        governor.castVote(
            proposalId,
            1
        );

        vm.roll(
            block.number +
            governor.votingPeriod() +
            1
        );

        bytes32 descriptionHash =
            keccak256(bytes(description));

        governor.queue(
            targets,
            values,
            calldatas,
            descriptionHash
        );

        vm.warp(
            block.timestamp + 2 days + 1
        );

        governor.execute(
            targets,
            values,
            calldatas,
            descriptionHash
        );

        assertEq(
            token.balanceOf(voter1),
            100_100 ether
        );
    }

    function testCannotVoteTwice() public {
        address[] memory targets =
            new address[](1);

        targets[0] = address(token);

        uint256[] memory values =
            new uint256[](1);

        bytes[] memory calldatas =
            new bytes[](1);

        calldatas[0] =
            abi.encodeWithSignature(
                "mint(address,uint256)",
                voter1,
                1 ether
            );

        uint256 proposalId =
            governor.propose(
                targets,
                values,
                calldatas,
                "Test"
            );

        vm.roll(
            block.number +
            governor.votingDelay() +
            1
        );

        vm.prank(voter1);

        governor.castVote(
            proposalId,
            1
        );

        vm.prank(voter1);

        vm.expectRevert();

        governor.castVote(
            proposalId,
            1
        );
    }

    function testProposalStateChanges()
        public
    {
        address[] memory targets =
            new address[](1);

        targets[0] = address(token);

        uint256[] memory values =
            new uint256[](1);

        bytes[] memory calldatas =
            new bytes[](1);

        calldatas[0] =
            abi.encodeWithSignature(
                "mint(address,uint256)",
                voter1,
                1 ether
            );

        uint256 proposalId =
            governor.propose(
                targets,
                values,
                calldatas,
                "State Test"
            );

        assertEq(
            uint256(
                governor.state(proposalId)
            ),
            0
        );

        vm.roll(
            block.number +
            governor.votingDelay() +
            1
        );

        assertEq(
            uint256(
                governor.state(proposalId)
            ),
            1
        );
    }

    function testQuorumIsConfigured()
        public
    {
        vm.roll(block.number + 10);

        uint256 quorum =
            governor.quorum(
                block.number - 1
            );

        assertGt(quorum, 0);
    }
}