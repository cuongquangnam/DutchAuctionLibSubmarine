pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "./DutchAuction.sol";

contract CypherpunkCoin is AccessControl, ERC20Burnable {
    bytes32 public constant AUCTION_CREATOR_ROLE = keccak256(
        "AUCTION_CREATOR_ROLE"
    );

    constructor(string memory name, string memory symbol)
        public
        ERC20(name, symbol)
    {
        //set up admin role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        //set up auction creator role
        _setupRole(AUCTION_CREATOR_ROLE, msg.sender);
        _mint(msg.sender, 1000);
        _setupDecimals(0);
    }

    address public auctionAddress;

    // prices in units of microEther
    function createDutchAuction(
        address _owner,
        uint256 _supply,
        uint256 _startCommitBlock,
        uint256 _endCommitBlock
    ) external {
        require(
            hasRole(AUCTION_CREATOR_ROLE, msg.sender),
            "CypherpunkCoin: must have auction creator role to create an auction"
        );
        DutchAuction auction = new DutchAuction(this, _owner);
        transfer(address(auction), _supply);
        auctionAddress = address(auction);
    }

    // set up the role of auction creators for others
    function setupDutchAuctionCreatorRole(address creator) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "This function can only be accessed by admin"
        );
        _setupRole(AUCTION_CREATOR_ROLE, creator);
    }

    // to receive money from others
    receive() external payable {}
}
