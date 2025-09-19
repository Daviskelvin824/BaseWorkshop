// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/BasedToken.sol"; // adjust path if needed

contract BasedTokenTest is Test {
    BasedToken token;
    address deployer = address(0x1);
    address alice = address(0x2);
    address bob   = address(0x3);

    uint256 initialSupply = 1000 ether;

    function setUp() public {
        vm.startPrank(deployer);
        token = new BasedToken(initialSupply);
        vm.stopPrank();
    }

    // ------------------------------------------------------------
    // Deployment
    // ------------------------------------------------------------
    function testDeployment() public view {
        assertEq(token.totalSupply(), initialSupply);
        assertEq(token.balanceOf(deployer), initialSupply);
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), deployer));
        assertTrue(token.hasRole(token.MINTER_ROLE(), deployer));
        assertTrue(token.hasRole(token.PAUSER_ROLE(), deployer));
    }

    // ------------------------------------------------------------
    // Minting
    // ------------------------------------------------------------
    function testMintAsMinter() public {
        vm.startPrank(deployer);
        token.mint(alice, 100 ether);
        vm.stopPrank();

        assertEq(token.balanceOf(alice), 100 ether);
    }

    function test_RevertMintWithoutRole() public {
        vm.prank(alice);
        vm.expectRevert(); // access control revert
        token.mint(alice, 100 ether);
    }

    function test_RevertMintZeroAmount() public {
        vm.startPrank(deployer);
        vm.expectRevert(); // amount must be > 0
        token.mint(alice, 0);
        vm.stopPrank();
    }

    // ------------------------------------------------------------
    // Pause & Unpause
    // ------------------------------------------------------------
    function testPauseAndUnpause() public {
        vm.startPrank(deployer);
        token.pause();
        assertTrue(token.paused());

        token.unpause();
        assertFalse(token.paused());
        vm.stopPrank();
    }

    function test_RevertPauseWithoutRole() public {
        vm.prank(alice);
        vm.expectRevert(); // access control revert
        token.pause();
    }

    function testCannotTransferWhenPaused() public {
        vm.startPrank(deployer);
        token.pause();
        vm.stopPrank();

        vm.prank(deployer);
        vm.expectRevert();
        token.transfer(alice, 1 ether);
    }

    // ------------------------------------------------------------
    // Blacklist
    // ------------------------------------------------------------
    function testBlacklistPreventsTransfer() public {
        vm.startPrank(deployer);
        token.setBlacklist(alice, true);
        vm.stopPrank();

        vm.prank(deployer);
        vm.expectRevert();
        token.transfer(alice, 1 ether);
    }

    function test_RevertBlacklistByNonAdmin() public {
        vm.prank(alice);
        vm.expectRevert(); // only admin
        token.setBlacklist(bob, true);
    }

    // ------------------------------------------------------------
    // Claim Reward
    // ------------------------------------------------------------
    function testClaimReward() public {
        uint256 reward = 10 * 10**token.decimals();

        vm.prank(alice);
        token.claimReward();
        assertEq(token.balanceOf(alice), reward);

        vm.prank(alice);
        vm.expectRevert(); // too soon
        token.claimReward();

        vm.warp(block.timestamp + 1 days);

        vm.prank(alice);
        token.claimReward();
        assertEq(token.balanceOf(alice), 2 * reward);
    }

    function test_RevertClaimRewardWhenBlacklisted() public {
        vm.startPrank(deployer);
        token.setBlacklist(alice, true);
        vm.stopPrank();

        vm.prank(alice);
        vm.expectRevert(); // blacklisted
        token.claimReward();
    }

    // ------------------------------------------------------------
    // Transfers
    // ------------------------------------------------------------
    function testTransferWorksNormally() public {
        vm.startPrank(deployer);
        token.transfer(alice, 100 ether);
        vm.stopPrank();

        assertEq(token.balanceOf(alice), 100 ether);
    }
}
