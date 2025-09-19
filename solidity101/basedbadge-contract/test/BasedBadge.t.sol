// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/BasedBadge.sol";

contract BasedBadgeTest is Test {
    BasedBadge badge;

    address owner;
    address alice;
    address bob;

    function setUp() public {
        // Create proper EOA addresses
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.startPrank(owner);
        badge = new BasedBadge();
        vm.stopPrank();
    }

    function testCreateCertificateType() public {
        vm.startPrank(owner);
        uint256 tokenId = badge.createBadgeType(
            "Solidity Cert",
            "CERTIFICATE",
            10,
            false,
            "ipfs://cert"
        );
        vm.stopPrank();

        (string memory name, string memory category,,,,) = badge.tokenInfo(tokenId);
        assertEq(name, "Solidity Cert");
        assertEq(category, "CERTIFICATE");
    }

    function testCreateWorkshop() public {
        vm.startPrank(owner);
        uint256[] memory sessionIds = badge.createWorkshop("Solidity Workshop", 3);
        vm.stopPrank();

        assertEq(sessionIds.length, 3);

        for (uint i = 0; i < sessionIds.length; i++) {
            (string memory name,,,,,) = badge.tokenInfo(sessionIds[i]);
            assertTrue(bytes(name).length > 0);
        }
    }

    function testBatchIssueBadges() public {
        vm.startPrank(owner);

        uint256 tokenId = badge.createBadgeType(
            "Event Badge",
            "EVENT_BADGE",
            100,
            true,
            "ipfs://event"
        );

        // Fixed array declaration
        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;

        badge.batchIssueBadges(recipients, tokenId, 2);

        vm.stopPrank();

        assertEq(badge.balanceOf(alice, tokenId), 2);
        assertEq(badge.balanceOf(bob, tokenId), 2);
    }

    function testGrantAchievement() public {
        vm.startPrank(owner);
        uint256 tokenId = badge.grantAchievement(alice, "Top Student", 1);
        vm.stopPrank();

        assertEq(badge.balanceOf(alice, tokenId), 1);
    }

    function testIssueBadge() public {
        vm.startPrank(owner);
        uint256 tokenId = badge.createBadgeType(
            "Participation Badge",
            "EVENT_BADGE",
            100,
            true,
            "ipfs://event2"
        );

        badge.issueBadge(alice, tokenId);
        vm.stopPrank();

        assertEq(badge.balanceOf(alice, tokenId), 1);
    }

    function testNonTransferableReverts() public {
        vm.startPrank(owner);
        uint256 tokenId = badge.createBadgeType(
            "Certificate",
            "CERTIFICATE",
            1,
            false,
            "ipfs://cert"
        );
        badge.issueBadge(alice, tokenId);
        vm.stopPrank();

        // Attempt transfer should revert
        vm.startPrank(alice);
        vm.expectRevert("This token is non-transferable");
        badge.safeTransferFrom(alice, bob, tokenId, 1, "");
        vm.stopPrank();
    }

    function testSetAndGetURI() public {
        vm.startPrank(owner);
        uint256 tokenId = badge.createBadgeType(
            "Workshop Token",
            "WORKSHOP",
            1,
            false,
            "ipfs://old"
        );
        badge.setURI(tokenId, "ipfs://new");
        vm.stopPrank();

        assertEq(badge.uri(tokenId), "ipfs://new");
    }

    function testVerifyExpiredToken() public {
        vm.startPrank(owner);
        uint256 tokenId = badge.createBadgeType(
            "Limited Cert",
            "CERTIFICATE",
            1,
            false,
            "ipfs://cert"
        );
        vm.stopPrank();

        (bool valid, uint256 earnedAt) = badge.verifyBadge(alice, tokenId);
        assertFalse(valid);
        assertEq(earnedAt, 0);
    }

    function testVerifyValidBadge() public {
        vm.startPrank(owner);
        uint256 tokenId = badge.createBadgeType(
            "Valid Cert",
            "CERTIFICATE",
            1,
            false,
            "ipfs://cert"
        );
        badge.issueBadge(alice, tokenId);
        vm.stopPrank();

        (bool valid, uint256 earnedAt) = badge.verifyBadge(alice, tokenId);
        assertTrue(valid);
        assertTrue(earnedAt > 0);
    }

    function testOnlyOwnerCanCreateBadgeType() public {
        vm.startPrank(alice);
        vm.expectRevert();
        badge.createBadgeType(
            "Unauthorized Badge",
            "CERTIFICATE",
            1,
            false,
            "ipfs://test"
        );
        vm.stopPrank();
    }

    function testOnlyOwnerCanIssueBadge() public {
        vm.startPrank(owner);
        uint256 tokenId = badge.createBadgeType(
            "Owner Only Badge",
            "CERTIFICATE",
            1,
            false,
            "ipfs://test"
        );
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert();
        badge.issueBadge(bob, tokenId);
        vm.stopPrank();
    }

    // Additional test to verify holderTokens tracking
    function testGetTokensByHolder() public {
        vm.startPrank(owner);
        
        uint256 tokenId1 = badge.createBadgeType(
            "Badge 1",
            "EVENT_BADGE",
            100,
            true,
            "ipfs://badge1"
        );
        
        uint256 tokenId2 = badge.createBadgeType(
            "Badge 2",
            "CERTIFICATE",
            10,
            false,
            "ipfs://badge2"
        );

        badge.issueBadge(alice, tokenId1);
        badge.issueBadge(alice, tokenId2);
        
        vm.stopPrank();

        uint256[] memory aliceTokens = badge.getTokensByHolder(alice);
        assertEq(aliceTokens.length, 2);
    }

    // Test for batch minting with different amounts
    function testBatchIssueBadgesWithDifferentAmounts() public {
        vm.startPrank(owner);

        uint256 tokenId = badge.createBadgeType(
            "Event Badge",
            "EVENT_BADGE",
            1000,
            true,
            "ipfs://event"
        );

        address[] memory recipients = new address[](3);
        recipients[0] = alice;
        recipients[1] = bob;
        recipients[2] = makeAddr("charlie");

        badge.batchIssueBadges(recipients, tokenId, 5);

        vm.stopPrank();

        assertEq(badge.balanceOf(alice, tokenId), 5);
        assertEq(badge.balanceOf(bob, tokenId), 5);
        assertEq(badge.balanceOf(recipients[2], tokenId), 5);
    }

    // Test max supply enforcement
    function testMaxSupplyEnforcement() public {
        vm.startPrank(owner);

        uint256 tokenId = badge.createBadgeType(
            "Limited Badge",
            "EVENT_BADGE",
            2,
            true,
            "ipfs://limited"
        );

        badge.issueBadge(alice, tokenId);
        badge.issueBadge(bob, tokenId);

        // This should revert as max supply is reached
        vm.expectRevert("Max supply reached");
        badge.issueBadge(makeAddr("charlie"), tokenId);

        vm.stopPrank();
    }
}