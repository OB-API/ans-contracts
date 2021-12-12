pragma solidity >=0.8.4;

import '../registry/ENS.sol';

/// Todo change the string to bytes32
// Next steps , check the hashRegistrar and passing the test cases, write the test cases, 
// 

contract NameAuction {

    ENS public ens;

    struct Auction {
        uint maxBid;
        uint secondBid;
        address winner;
    }

    uint public constant MIN_BID = 0.01 ether;
    uint public constant MIN_LABEL_LENGTH = 3;
    uint public constant MAX_LABEL_LENGTH = 6;

    address public owner;
    address public beneficiary;

    uint public biddingStarts;
    uint public biddingEnds;
    uint public revealEnds;
    uint public fundsAvailable;

    mapping(bytes32=>uint) public bids;
    mapping(bytes32=>Auction) auctions;
    mapping(bytes32=>address) labels;

    event BidPlaced(address indexed bidder, uint amount, bytes32 hash);
    event BidRevealed(address indexed bidder, bytes32 indexed labelHash, string label, uint amount);
    event AuctionFinalised(address indexed winner, bytes32 indexed labelHash, string label, uint amount);

    constructor(address ensAddress, uint _biddingStarts, uint _biddingEnds, uint _revealEnds, address _beneficiary) public {
        // require(_biddingStarts >= block.timestamp);
        // require(_biddingEnds > _biddingStarts);
        // require(_revealEnds > _biddingEnds);
        // require(_beneficiary != address(0));

        ens = ENS(ensAddress);
        ens.setAuctioner();
        owner = msg.sender;
        biddingStarts = _biddingStarts;
        biddingEnds = _biddingEnds;
        revealEnds = _revealEnds;
        beneficiary = _beneficiary;
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function placeBid(bytes32 bidHash) external payable {
        require(block.timestamp >= biddingStarts && block.timestamp < biddingEnds);

        require(msg.value >= MIN_BID);
        require(bids[bidHash] == 0);
        bids[bidHash] = msg.value;
        emit BidPlaced(msg.sender, msg.value, bidHash);
    }

    function revealBid(address bidder, bytes32 label, bytes32 secret) external {
        require(block.timestamp >= biddingEnds && block.timestamp < revealEnds);

        bytes32 bidHash = computeBidHash(bidder, label, secret);
        uint bidAmount = bids[bidHash];
        bids[bidHash] = 0;
        require(bidAmount > 0);

        // Immediately refund bids on invalid labels.
        uint labelLen = strlen(label);
        if(labelLen < MIN_LABEL_LENGTH || labelLen > MAX_LABEL_LENGTH) {
            payable(bidder).transfer(bidAmount);
            return;
        }

        emit BidRevealed(bidder, keccak256(abi.encodePacked(label)), bytes32ToString(label), bidAmount);

        Auction storage a = auctions[label];
        if(bidAmount > a.maxBid) {
            // New winner!
            if(a.winner != address(0)) {
                // Ignore failed sends - bad luck for them.
                payable(a.winner).send(a.maxBid);
            }
            a.secondBid = a.maxBid;
            a.maxBid = bidAmount;
            a.winner = bidder;
        } else if(bidAmount > a.secondBid) {
            // New second bidder
            a.secondBid = bidAmount;
            payable(bidder).transfer(bidAmount);
        } else {
            // No effect on the auction
            payable(bidder).transfer(bidAmount);
        }
    }

    function finaliseAuction(bytes32 label) external {
        require(block.timestamp >= revealEnds);

        Auction storage auction = auctions[label];
        require(auction.winner != address(0));

        uint winPrice = auction.secondBid;
        if(winPrice == 0) {
            winPrice = MIN_BID;
        }
        if(winPrice < auction.maxBid) {
            // Ignore failed sends
            payable(auction.winner).send(auction.maxBid - winPrice);
        }
        fundsAvailable += winPrice;
        ens.setTldRecord(label, auction.winner);
        emit AuctionFinalised(auction.winner, keccak256(abi.encodePacked(label)), bytes32ToString(label), winPrice);

        labels[label] = auction.winner;
        delete auctions[label];
    }

    function withdraw() external {
        require(msg.sender == owner);
        payable(msg.sender).transfer(fundsAvailable);
        fundsAvailable = 0;
    }

    function auction(bytes32 name) external view returns(uint maxBid, uint secondBid, address winner) {
        Auction storage a = auctions[name];
        return (a.maxBid, a.secondBid, a.winner);
    }

    function labelOwner(bytes32 name) external view returns(address) {
        return labels[name];
    }

    function computeBidHash(address bidder, bytes32 name, bytes32 secret) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(bidder, name, secret));
    }

    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(bytes32 s) internal pure returns (uint) {
        s; // Don't warn about unused variables
        // Starting here means the LSB will be the byte we care about
        uint ptr;
        uint end;
        assembly {
            ptr := add(s, 1)
            end := add(mload(s), ptr)
        }
        uint len = 0;
        for (len = 0; ptr < end; len++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
        return len;
    }
}