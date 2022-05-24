
contract Auction{

    address payable public owner;
    uint public startTime;
    uint public endTime;

    enum AuctionState {started, running, ended , cancelled}
    AuctionState public auctionState;

    uint public highestBid;
    uint public highestPayableBid;
    uint public bidIncrement;

    address payable public highestBidder;

    mapping(address => uint) public bids;
    constructor(){
        owner=payable(msg.sender);
        auctionState= AuctionState.running;
        startTime=block.number;
        endTime = startTime+ 240;
        bidIncrement= 1 ether;
    }
    modifier notOwner(){
        require(msg.sender != owner,"Owner cannot bid");
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == owner,"Owner cannot bid");
        _;
    }
    modifier started(){
        require(block.number>startTime);
        _;
    }
    modifier beforeEnding(){
        require(block.number<endTime);
        _;
    }
    function cancel() public onlyOwner{
            auctionState=AuctionState.cancelled;
    }
    function end() public onlyOwner{
            auctionState=AuctionState.ended;
    }
    function min(uint a, uint b) pure private returns(uint){
        if(a<b){
            return a ;
        }else{
            return b;
        }
    }
    function bid() payable public notOwner started beforeEnding{
        require(auctionState==AuctionState.running);
        require(msg.value>=1 ether);

        uint currentbid = bids[msg.sender]+ msg.value;
        require(currentbid>highestPayableBid);

        bids[msg.sender]=currentbid;

        if(currentbid<bids[highestBidder]){
            highestPayableBid= min(currentbid+bidIncrement,bids[highestBidder]);
        }else{
            highestPayableBid = min(currentbid,bids[highestBidder]+bidIncrement);
            highestBidder = payable(msg.sender);
        }



    }
    function finalizeAuc() public {
        require(auctionState==AuctionState.cancelled || auctionState==AuctionState.ended || block.number>endTime);
        require(msg.sender == owner ||  bids[msg.sender]>0);

        address payable person;
        uint value;
        if(auctionState==AuctionState.cancelled){
            person = payable(msg.sender);
            value= bids[msg.sender];
        }else{
            if(msg.sender== owner){
                person=owner;
                value=highestPayableBid;
            }else{
                if(msg.sender== highestBidder){
                    person=highestBidder;
                    value=bids[highestBidder]-highestPayableBid;
                }else{
                    person=payable(msg.sender);
                    value=bids[msg.sender];
                }
            }
        }
        bids[msg.sender]=0;
        person.transfer(value);

    }

}