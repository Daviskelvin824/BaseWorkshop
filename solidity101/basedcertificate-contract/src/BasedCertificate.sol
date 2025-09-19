// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BasedCertificate
 * @dev NFT-based certificate system for achievements, graduation, or training
 * Features:
 * - Soulbound (non-transferable)
 * - Metadata for certificate details
 * - Issuer-controlled (onlyOwner)
 */
contract BasedCertificate is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;

    struct CertificateData {
        string recipientName;
        string course;
        string issuer;
        uint256 issuedDate;
        bool valid;
    }

    // --- Mappings ---
    // TODO: Add mappings
    mapping(uint256 => CertificateData) public certificates;
    mapping(address => uint256[]) public ownerCertificates; // Track all certs per owner
    mapping(bytes32 => uint256) public certHashToTokenId; // Prevent duplicate certificate by hash

    // --- Events ---
    event CertificateIssued(
        uint256 indexed tokenId,
        address recipient,
        string course,
        string issuer
    );
    event CertificateRevoked(uint256 indexed tokenId);
    event CertificateUpdated(uint256 indexed tokenId, string newCourse);

    constructor() ERC721("Based Certificate", "BCERT") Ownable(msg.sender) {}

    /**
     * @dev Issue a new certificate
     * Use case: Awarding completion or graduation
     */
    function issueCertificate(
        address to,
        string memory recipientName,
        string memory course,
        string memory issuer,
        string memory uri
    ) public onlyOwner {
        require(to != address(0), "BCERT: invalid recipient");
        // TODO: Implement issuance
        // 1. Check duplicate (optional: via hash)
        bytes32 certHash = keccak256(abi.encodePacked(recipientName, course, issuer));
        require(certHashToTokenId[certHash] == 0, "BCERT: certificate already issued");
        // 2. Mint new NFT
        uint256 tokenId = ++_nextTokenId;
        _safeMint(to, tokenId);
        // 3. Set token URI (certificate metadata file)
        _setTokenURI(tokenId, uri);
        // 4. Save certificate data
        certificates[tokenId] = CertificateData({
            recipientName: recipientName,
            course: course,
            issuer: issuer,
            issuedDate: block.timestamp,
            valid: true
        });
        // 5. Update mappings
        ownerCertificates[to].push(tokenId);
        certHashToTokenId[certHash] = tokenId;
        // 6. Emit event
        emit CertificateIssued(tokenId, to, course, issuer);
    }

    /**
     * @dev Revoke a certificate (e.g. if mistake or fraud)
     */
    function revokeCertificate(uint256 tokenId) public onlyOwner {
        // TODO: Check token exists
        require(_ownerOf(tokenId) != address(0), "BCERT: token does not exist");
        require(certificates[tokenId].valid, "BCERT: already revoked");
        // Mark certificate invalid
        certificates[tokenId].valid = false;
        // Emit event
        emit CertificateRevoked(tokenId);
    }

    /**
     * @dev Update certificate data (optional, for corrections)
     */
    function updateCertificate(uint256 tokenId, string memory newCourse) public onlyOwner {
        // TODO: Check token exists
        require(_ownerOf(tokenId) != address(0), "BCERT: token does not exist");
        require(certificates[tokenId].valid, "BCERT: certificate not valid");
        // Update course field
        certificates[tokenId].course = newCourse;
        // Emit event
        emit CertificateUpdated(tokenId, newCourse);
    }

    /**
     * @dev Get all certificates owned by an address
     */
    function getCertificatesByOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        // TODO: Return certificate based on owner
        return ownerCertificates[owner];
    }

    /**
    * @dev Burn a certificate (soulbound cleanup)
    */
    function burnCertificate(uint256 tokenId) public onlyOwner {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "BCERT: token does not exist");

        // --- Clean up mappings before burning ---
        delete certificates[tokenId];

        uint256[] storage certs = ownerCertificates[owner];
        for (uint256 i = 0; i < certs.length; i++) {
            if (certs[i] == tokenId) {
                certs[i] = certs[certs.length - 1];
                certs.pop();
                break;
            }
        }

        // --- Burn the NFT ---
        super._burn(tokenId);
    }

    /**
    * @dev Override transfer functions to make non-transferable (soulbound)
    */
    function _update(address to, uint256 tokenId, address auth) internal override returns(address) {
        address from = _ownerOf(tokenId);
        // TODO: Only allow minting (from == address(0)) and burning (to == address(0))
        // Only allow minting (from == 0) or burning (to == 0)
        require(
            from == address(0) || to == address(0),
            "BCERT: certificates are non-transferable"
        );
        // super._update(to, tokenId, auth);
        super._update(to, tokenId, auth);
        return from;
    }

    // --- Overrides for multiple inheritance ---

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}
