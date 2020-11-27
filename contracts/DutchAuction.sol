pragma solidity ^0.4.24;
import "./LibSubmarineSimple.sol";
import "./CypherpunkCoin.sol";

contract DutchAuction is LibSubmarineSimple {
    uint256 public endAuctionTxBlockNumber;
    uint256 public endAuctionTxIndex;
    bool public canfinalize;
    uint256 public constant startCommitBlock;
    uint256 public constant endCommitBlock;
    CypherpunkCoin public token;
    address public owner;
    uint256 public clearingPrice;
    uint256 public ethRefundLastBidder;
    address public lastBidder;

    // start the auction with specified commitment period, owner and token
    constructor(
        Cypherpunk _token,
        address _owner,
        uint256 _startCommitBlock,
        uint256 _endCommitBlock
    ) public {
        token = _token;
        owner = _owner;
        startCommitBlock = _startCommitBlock;
        endCommitBlock = _endCommitBlock;
    }

    // owner based on the events Revealed and Unlocked emitted by the contract
    // to set these attributes
    function prepareFinalize(
        uint256 _endAuctionTxBlockNumber,
        uint256 _endAuctionTxIndex,
        uint256 _clearingPrice,
        uint256 _ethRefundLastBidder,
        address _lastBidder
    ) public {
        require(msg.sender == owner);
        // set the transaction that ends the auction
        endAuctionTxBlockNumber = _endAuctionTxBlockNumber;
        endAuctionTxIndex = _endAuctionTxIndex;
        clearingPrice = _clearingPrice;
        lastBidder = _lastBidder;
        ethRefundLastBidder = _ethRefundLastBidder;
        canfinalize = true;
    }

    // a bidder call this function to take their tokens if their commitment are valid to do so
    // or get their ETH back
    function finalize(bytes32 _submarineId) {
        require(
            canfinalize,
            "Have to wait for the owner to set the ending block transaction"
        );
        require(
            revealedAndUnlocked(_submarineId),
            "The commitment has not been revealed or unlocked"
        );
        SubmarineSession ss = sessions[_submarineId];

        // check whether the commit transaction is in the specified window
        if (
            ss.commitTxBlockNumber >= startCommitBlock &&
            (ss.commitTxBlockNumber < endAuctionTxBlockNumber ||
                (ss.commitTxBlockNumber == endAuctionTxBlockNumber &&
                    ss.commitTxIndex <= endAuctionTxIndex))
        ) {
            // check whether the bidder is the last bidder
            if (
                bidders[_submarineId] == lastBidder && ethRefundLastBidder != 0
            ) {
                address payable bidderPayable = address(
                    uint160(address(bidders[_submarineId]))
                );
                ss.amountRevealed = ss.amountRevealed.sub(ethRefundLastBidder);
                bidderPayable.transfer(ethRefundLastBidder);
            }
            token.transfer(
                bidders[_submarineId],
                ss.amountRevealed.div(clearingPrice)
            );
        } else bidders[_submarineId].transfer(ss.amountUnlocked);
    }

    // function executed on every revealing
    function onSubmarineReveal(
        bytes32 _submarineId,
        bytes _embeddedDAppData,
        uint256 _value,
        uint32 _commitTxBlockNumber
    ) {
        // require the commit to be in the specified period
        require(
            _commitTxBlockNumber >= startCommitBlock &&
                _commitTxBlockNumber <= endCommitBlock,
            "The commitment has to be in the committing window"
        );

        bidders[_submarineId] = msg.sender;
    }
}
