// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/BasedCertificate.sol";

contract BasedCertificateTest is Test {
    BasedCertificate cert;

    address owner = address(0x1);
    address alice = address(0x2);
    address bob   = address(0x3);

    function setUp() public {
        vm.prank(owner);
        cert = new BasedCertificate();
    }

    // ------------------------------------------------------------
    // Deployment
    // ------------------------------------------------------------
    function testDeployment() public view {
        assertEq(cert.name(), "Based Certificate");
        assertEq(cert.symbol(), "BCERT");
        assertEq(cert.owner(), owner);
    }

    // ------------------------------------------------------------
    // Issue
    // ------------------------------------------------------------
    function testIssueCertificate() public {
        vm.startPrank(owner);
        cert.issueCertificate(
            alice,
            "Alice",
            "Solidity 101",
            "Based Academy",
            "ipfs://cert1"
        );
        vm.stopPrank();

        assertEq(cert.balanceOf(alice), 1);
        assertEq(cert.getCertificatesByOwner(alice).length, 1);

        // ✅ Now tokenId starts at 1
        (
            string memory name,
            string memory course,
            string memory issuer,
            uint256 issuedDate,
            bool valid
        ) = cert.certificates(1);

        assertEq(name, "Alice");
        assertEq(course, "Solidity 101");
        assertEq(issuer, "Based Academy");
        assertTrue(valid);
        assertGt(issuedDate, 0);
    }


    function test_RevertDuplicateCertificate() public {
        vm.startPrank(owner);
        cert.issueCertificate(alice, "Alice", "Solidity 101", "Based Academy", "ipfs://cert1");
        vm.expectRevert("BCERT: certificate already issued");
        cert.issueCertificate(alice, "Alice", "Solidity 101", "Based Academy", "ipfs://cert2");
        vm.stopPrank();
    }

   
    // ------------------------------------------------------------
    // Revoke
    // ------------------------------------------------------------
    function testRevokeCertificate() public {
        vm.startPrank(owner);
        cert.issueCertificate(alice, "Alice", "Course A", "Issuer A", "uri");
        cert.revokeCertificate(1);
        (, , , , bool valid) = cert.certificates(1);
        assertFalse(valid);

        vm.stopPrank();
        }

        function test_RevertRevokeNonexistent() public {
            vm.prank(owner);
            vm.expectRevert("BCERT: token does not exist");
            cert.revokeCertificate(99);
        }

        // ------------------------------------------------------------
        // Update
        // ------------------------------------------------------------
        function testUpdateCertificate() public {
        vm.startPrank(owner);

        cert.issueCertificate(owner, "Alice", "Course A", "Issuer A", "uri");
        cert.updateCertificate(1, "Course B");

        (
            string memory name,
            string memory course,
            string memory issuer,
            uint256 issuedDate,
            bool valid
        ) = cert.certificates(1);

        assertEq(name, "Alice");
        assertEq(course, "Course B"); // ✅ Fixed expectation
        assertEq(issuer, "Issuer A");
        assertGt(issuedDate, 0);
        assertTrue(valid);

        vm.stopPrank();
    }

    function test_RevertIssueByNonOwner() public {
        address nonOwner = alice;
        vm.prank(nonOwner);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                nonOwner
            )
        );
        cert.issueCertificate(owner, "Alice", "Course", "Issuer", "uri");
    }

    function testBurnCertificate() public {
        vm.startPrank(owner);

        cert.issueCertificate(owner, "Alice", "Course A", "Issuer A", "uri");
        cert.burnCertificate(1);

        // After burn, tokenURI(1) must revert
        vm.expectRevert(
            abi.encodeWithSignature("ERC721NonexistentToken(uint256)", 1)
        );
        cert.tokenURI(1);

        vm.stopPrank();
    }




}
