// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title BasedBadge
 * @dev ERC1155 multi-token for badges, certificates, and achievements
 * Token types:
 * - Non-transferable certificates
 * - Fungible event badges
 * - Limited achievement medals
 * - Workshop session tokens
 */
contract BasedBadge is ERC1155, AccessControl, Pausable, ERC1155Supply {
    // --- Role definitions ---
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // --- Token ID ranges for organization ---
    uint256 public constant CERTIFICATE_BASE = 1000;
    uint256 public constant EVENT_BADGE_BASE = 2000;
    uint256 public constant ACHIEVEMENT_BASE = 3000;
    uint256 public constant WORKSHOP_BASE = 4000;

    // --- Token metadata structure ---
    struct TokenInfo {
        string name;
        string category;
        uint256 maxSupply;
        bool isTransferable;
        uint256 validUntil; // 0 = no expiry
        address issuer;
    }

    // --- Mappings ---
    // TODO: Add mappings
    mapping(uint256 => TokenInfo) public tokenInfo;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256[]) public holderTokens;
    mapping(uint256 => mapping(address => uint256)) public earnedAt;

    // --- Counters for unique IDs ---
    uint256 private _certificateCounter;
    uint256 private _eventCounter;
    uint256 private _achievementCounter;
    uint256 private _workshopCounter;

    // --- Events ---
    event TokenTypeCreated(uint256 indexed tokenId, string name, string category);
    event BadgeIssued(uint256 indexed tokenId, address to);
    event BatchBadgesIssued(uint256 indexed tokenId, uint256 count);
    event AchievementGranted(uint256 indexed tokenId, address student, string achievement);

    constructor() ERC1155("") {
        // --- Setup roles ---
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Create new badge or certificate type
     */
    function createBadgeType(
        string memory name,
        string memory category,
        uint256 maxSupply,
        bool transferable,
        string memory uri
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        // TODO:
        // 1. Pick category range (CERTIFICATE_BASE, EVENT_BADGE_BASE, etc.)
        uint256 tokenId;
        // 2. Increment counter for uniqueness
        if (keccak256(bytes(category)) == keccak256("CERTIFICATE")) {
            _certificateCounter++;
            tokenId = CERTIFICATE_BASE + _certificateCounter;
        } else if (keccak256(bytes(category)) == keccak256("EVENT_BADGE")) {
            _eventCounter++;
            tokenId = EVENT_BADGE_BASE + _eventCounter;
        } else if (keccak256(bytes(category)) == keccak256("ACHIEVEMENT")) {
            _achievementCounter++;
            tokenId = ACHIEVEMENT_BASE + _achievementCounter;
        } else if (keccak256(bytes(category)) == keccak256("WORKSHOP")) {
            _workshopCounter++;
            tokenId = WORKSHOP_BASE + _workshopCounter;
        } else {
            revert("Invalid category");
        }
        // 3. Store TokenInfo
        tokenInfo[tokenId] = TokenInfo({
            name: name,
            category: category,
            maxSupply: maxSupply,
            isTransferable: transferable,
            validUntil: 0,
            issuer: msg.sender
        });
        // 4. Save URI
        _tokenURIs[tokenId] = uri;
        // 5. Emit TokenTypeCreated
        emit TokenTypeCreated(tokenId, name, category);
        // 6. Return tokenId
        return tokenId;
    }

    /**
     * @dev Issue single badge/certificate to user
     */
    function issueBadge(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        // TODO:
        // 1. Verify tokenId exists
        require(bytes(tokenInfo[tokenId].name).length > 0, "Token does not exist");
        // 2. Check supply limit
        require(totalSupply(tokenId) < tokenInfo[tokenId].maxSupply, "Max supply reached");
        // 3. Mint token to user
        _mint(to, tokenId, 1, "");
        // 4. Record timestamp
        earnedAt[tokenId][to] = block.timestamp;
        // 5. Save to holderTokens
        holderTokens[to].push(tokenId);
        // 6. Emit BadgeIssued
        emit BadgeIssued(tokenId, to);
    }

    /**
     * @dev Batch mint badges for events
     */
    function batchIssueBadges(address[] memory recipients, uint256 tokenId, uint256 amount)
        public onlyRole(MINTER_ROLE)
    {
        // TODO:
        require(bytes(tokenInfo[tokenId].name).length > 0, "Token does not exist");
        require(totalSupply(tokenId) + (recipients.length * amount) <= tokenInfo[tokenId].maxSupply, "Max supply exceeded");
        // Loop through recipients
        // Mint amount to each
        // Record timestamp
        // Emit BatchBadgesIssued
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], tokenId, amount, "");
            holderTokens[recipients[i]].push(tokenId);
            earnedAt[tokenId][recipients[i]] = block.timestamp;
        }
        emit BatchBadgesIssued(tokenId, recipients.length);
    }

    /**
     * @dev Grant special achievement to student
     */
    function grantAchievement(address student, string memory achievementName, uint256 rarity)
        public onlyRole(MINTER_ROLE) returns (uint256)
    {
        // TODO:
        // 1. Generate achievement tokenId
        _achievementCounter++;
        uint256 tokenId = ACHIEVEMENT_BASE + _achievementCounter;
        // 2. Store TokenInfo (rarity affects maxSupply)
        tokenInfo[tokenId] = TokenInfo({
            name: achievementName,
            category: "ACHIEVEMENT",
            maxSupply: rarity, // rarity = maxSupply
            isTransferable: false,
            validUntil: 0,
            issuer: msg.sender
        });
        // 3. Mint 1 achievement NFT
        _mint(student, tokenId, 1, "");
        // 4. Emit AchievementGranted
        holderTokens[student].push(tokenId);
        earnedAt[tokenId][student] = block.timestamp;
        emit AchievementGranted(tokenId, student, achievementName);
        // 5. Return tokenId
        return tokenId;
    }

    /**
     * @dev Create workshop series with multiple sessions
     */
    function createWorkshop(string memory seriesName, uint256 totalSessions)
        public onlyRole(MINTER_ROLE) returns (uint256[] memory)
    {
        // TODO:
        uint256[] memory sessionIds = new uint256[](totalSessions);
        // 1. Loop for totalSessions
        // 2. Generate tokenIds under WORKSHOP_BASE
        // 3. Store TokenInfo
        for (uint256 i = 0; i < totalSessions; i++) {
            _workshopCounter++;
            uint256 tokenId = WORKSHOP_BASE + _workshopCounter;
            tokenInfo[tokenId] = TokenInfo({
                name: string(abi.encodePacked(seriesName, " Session ", Strings.toString(i+1))),
                category: "WORKSHOP",
                maxSupply: 1,
                isTransferable: false,
                validUntil: 0,
                issuer: msg.sender
            });
            sessionIds[i] = tokenId;
        }
        // 4. Return array of session IDs
        return sessionIds;
    }

    /**
     * @dev Set metadata URI
     */
    function setURI(uint256 tokenId, string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        // TODO: Store URI in mapping
        _tokenURIs[tokenId] = newuri;
    }

    /**
     * @dev Get all tokens owned by a student
     */
    function getTokensByHolder(address holder) public view returns (uint256[] memory) {
        // TODO: Return tokenId list
        return holderTokens[holder];
    }

    /**
     * @dev Verify badge validity
     */
    function verifyBadge(address holder, uint256 tokenId)
        public view returns (bool valid, uint256 earnedTimestamp)
    {
        // TODO:
        // 1. Check balance > 0
        uint256 balance = balanceOf(holder, tokenId);
        if (balance == 0) return (false, 0);
        // 2. Check expiry (if any)
        TokenInfo memory info = tokenInfo[tokenId];
        if (info.validUntil != 0 && block.timestamp > info.validUntil) return (false, earnedAt[tokenId][holder]);
        // 3. Return status + timestamp
        return (true, earnedAt[tokenId][holder]);
    }

    /**
     * @dev Pause / unpause transfers
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Restrict transferability and check pause
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        // TODO: Restrict non-transferable tokens
        for (uint i = 0; i < ids.length; i++) {
           if (from != address(0) && to != address(0)) {
               require(
                   tokenInfo[ids[i]].isTransferable,
                   "This token is non-transferable"
               );
           }
        }
        super._update(from, to, ids, values);
    }

    /**
     * @dev Return custom URI
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Check interface support
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
