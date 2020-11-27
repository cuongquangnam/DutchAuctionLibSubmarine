import "./LibSubmarineSimple";
import "./CypherpunkCoin";

contract DutchAuction is LibSubmarineSimple {
    uint256 public endAuctionTxBlockNumber;
    uint256 public endAuctionTxIndex;
    bool public canClaim;
    uint256 public constant startCommitBlock;
    uint256 public constant endCommitBlock;
    CypherpunkCoin public token;
    address public owner;

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

    // owner based on the events Revealed and Unlocked of the contract
    // to set these attributes
    function setEndingBlockTransaction(
        uint256 _endAuctionTxBlockNumber,
        uint256 _endAuctionTxIndex,
        uint256 _clearingPrice,
        uint256 _ethRefundLastBidder,
        address _lastBidder
    ) public {
        require(msg.sender == owner);
        endAuctionTxBlockNumber = _endAuctionTxBlockNumber;
        endAuctionTxIndex = _endAuctionTxIndex;
        clearingPrice = _clearingPrice;
        lastBidder = _lastBidder;
        ethRefundLastBidder = _ethRefundLastBidder;
        canClaim = true;
    }

    function finalize(bytes32 _submarineId) {
        require(
            canclaim,
            "Have to wait for the owner to set the ending block transaction"
        );
        require(
            revealedAndUnlocked(_submarineId),
            "The commitment has not been revealed or unlocked"
        );
        SubmarineSession ss = sessions[_submarineId];

        if (
            ss.commitTxBlockNumber >= startCommitBlock &&
            (ss.commitTxBlockNumber < endAuctionTxBlockNumber ||
                (ss.commitTxBlockNumber == endAuctionTxBlockNumber &&
                    ss.commitTxIndex <= endAuctionTxIndex))
        ) {
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

    function onSubmarineReveal(
        bytes32 _submarineId,
        bytes _embeddedDAppData,
        uint256 _value
    ) {
        require(
            _commitTxBlockNumber >= startCommitBlock &&
                _commitTxBlockNumber <= endCommitBlock,
            "The commitment has to be in the committing window"
        );

        bidders[_submarineId] = msg.sender;
    }
}
