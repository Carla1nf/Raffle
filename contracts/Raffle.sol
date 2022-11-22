pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "erc721a/contracts/IERC721A.sol";

error notEnoughAvailableTickets();
error RaffleisOffline();
error SpecificTimeisnotSupported();
error YouareNotPart();
error NotAvailable();
error NotEnoughFounds();
error TicketsAlreadyBought();
error NotEnoughTickets();

interface IStakingP {
    function deposit() external payable;
}

contract Raffle is
    ERC1155Holder,
    ERC721Holder,
    ReentrancyGuard,
    VRFConsumerBaseV2
{
    VRFCoordinatorV2Interface COORDINATOR;

    enum State {
        Active,
        Waiting,
        Finished
    }

    enum Type {
        ERC721,
        ERC721A,
        ERC1155
    }
    struct Raffles {
        uint256 id;
        uint256 tickets;
        uint256 endTime;
        uint256 liveTime;
        State _state;
        address winner;
        uint256 ticketsBought;
        uint256 pricePerTicket;
        uint256 preOrderFunds;
        address collectionAdd;
        address payable owner;
        uint256 nftId;
        Type types;
    }

    address public s_Owner;
    address public s_Relayer;
    address s_Staking;
    address constant _vrfCoordinator =
        0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    bytes32 constant keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint64 constant s_subscriptionId = 764;
    uint256 public s_FEE;
    uint256 public s_ID;
    uint256 s_stakingFee = 100;
    uint256 s_requestId;
    uint256[] private s_randomWords;
    uint16 constant requestConfirmations = 3;
    uint32 constant callbackGasLimit = 950000;
    uint32 constant numWords = 1;
    uint256 public s_LastId = 0;

    constructor() VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_FEE = 0.01 ether;
        s_Owner = msg.sender;
    }

    mapping(uint256 => Raffles) rafflesId;
    mapping(address => uint256[]) rafflesIdperUser;
    mapping(uint256 => mapping(uint256 => address)) public players;
    mapping(uint256 => uint256) public realPlayersPerRaffle;
    mapping(uint256 => mapping(uint256 => address)) public addressPerPlayer;
    mapping(address => mapping(uint256 => uint256)) public ticketsPerUser;
    mapping(address => uint256[]) boughtRaffles;
    mapping(uint256 => uint256) public rafflePerRequest;
    mapping(uint256 => uint256) public numberPerRaffle;
    mapping(address => uint256) public winsCount;

    event CreatedRaffle(uint256 _id, uint256 ticketsAmount, address owner);
    event WinnerPicked(uint256 raffleId, address owner);

    modifier onlyOwner() {
        if (msg.sender != s_Owner) {
            revert NotAvailable();
        }
        _;
    }

    modifier onlyRelayer() {
        if (msg.sender != s_Relayer) {
            revert NotAvailable();
        }
        _;
    }

    function startYourRaffle(
        uint256 tickets,
        uint256 price,
        address _nftAddress,
        uint256 _nftId,
        uint256 erc721Type,
        uint256 end
    ) public payable {
        if (!(end == 172800 || end == 43200 || end == 86400)) {
            revert SpecificTimeisnotSupported();
        }

        if (price < 1000000000000000) {
            revert();
        }

        if (tickets < 50) {
            revert NotEnoughTickets();
        }

        Type _type;

        if (erc721Type == 0) {
            IERC721 collection = IERC721(_nftAddress);
            collection.safeTransferFrom(msg.sender, address(this), _nftId, "");
            _type = Type.ERC721;
        } else if (erc721Type == 1) {
            IERC1155 sCollection = IERC1155(_nftAddress);
            sCollection.safeTransferFrom(
                msg.sender,
                address(this),
                _nftId,
                1,
                ""
            );
            _type = Type.ERC1155;
        } else {
            IERC721A rCollection = IERC721A(_nftAddress);
            rCollection.safeTransferFrom(msg.sender, address(this), _nftId, "");
            _type = Type.ERC721A;
        }
        require(msg.value >= s_FEE);

        s_ID++;
        uint256 m_ID = s_ID;
        rafflesId[m_ID] = Raffles(
            m_ID,
            tickets,
            block.timestamp + end,
            end,
            State.Active,
            payable(0x0),
            0,
            price,
            msg.value,
            _nftAddress,
            payable(msg.sender),
            _nftId,
            _type
        );
        rafflesIdperUser[msg.sender].push(m_ID);

        emit CreatedRaffle(m_ID, tickets, msg.sender);
    }

    function buyTickets(uint256 _id, uint256 amount) public payable {
        Raffles memory m_Raffle = rafflesId[_id];
        if (
            m_Raffle._state == State.Finished ||
            m_Raffle._state == State.Waiting
        ) {
            revert RaffleisOffline();
        }

        if (amount * m_Raffle.pricePerTicket > msg.value) {
            revert();
        }

        if (m_Raffle.ticketsBought + amount > m_Raffle.tickets) {
            revert notEnoughAvailableTickets();
        }
        if (amount == 0) {
            revert();
        }

        if (ticketsPerUser[msg.sender][_id] == 0) {
            boughtRaffles[msg.sender].push(_id);
            realPlayersPerRaffle[_id]++;
            addressPerPlayer[_id][realPlayersPerRaffle[_id]] = msg.sender;
        }

        ticketsPerUser[msg.sender][_id] += amount;
        rafflesId[_id].ticketsBought += amount;
        players[_id][m_Raffle.ticketsBought] = msg.sender;

        if (amount > 1) {
            players[_id][m_Raffle.ticketsBought + amount - 1] = msg.sender;
        }
    }

    function requestWinner(uint256 _id) internal {
        if (rafflesId[_id].winner != payable(0x0)) {
            revert RaffleisOffline();
        }

        rafflesId[_id]._state = State.Waiting;
        uint256 funds = rafflesId[_id].preOrderFunds;
        delete rafflesId[_id].preOrderFunds;
        requestRandomWords(_id);
        (bool success, ) = msg.sender.call{value: funds}("");
    }

    function pickWinner(uint256 _id, uint256 _randomNumber) internal {
        if (rafflesId[_id].winner != payable(0x0)) {
            revert NotAvailable();
        }

        Raffles memory m_Raffle = rafflesId[_id];
        uint256 randomNumber = (_randomNumber % m_Raffle.ticketsBought);
        address winner = players[_id][randomNumber];
        if (winner == payable(0x0)) {
            winner = findWinner(_id, randomNumber, m_Raffle.ticketsBought);
        }
        rafflesId[_id].winner = winner;
        winsCount[winner]++;
        rafflesId[_id]._state = State.Finished;
        if (m_Raffle.types == Type.ERC721) {
            IERC721 collection = IERC721(m_Raffle.collectionAdd);
            collection.safeTransferFrom(
                address(this),
                rafflesId[_id].winner,
                m_Raffle.nftId,
                ""
            );
        } else if (m_Raffle.types == Type.ERC1155) {
            IERC1155 _collection = IERC1155(m_Raffle.collectionAdd);
            _collection.safeTransferFrom(
                address(this),
                rafflesId[_id].winner,
                m_Raffle.nftId,
                1,
                ""
            );
        } else {
            IERC721A rCollection = IERC721A(m_Raffle.collectionAdd);
            rCollection.safeTransferFrom(
                address(this),
                rafflesId[_id].winner,
                m_Raffle.nftId,
                ""
            );
        }
        if (m_Raffle.liveTime >= 172800) {
            s_LastId = _id;
        }

        uint256 funds = calculateFunds(_id);
        uint256 fee = calculateFee(funds);
        funds -= fee;
        payable(m_Raffle.owner).transfer(funds);
        IStakingP stakings = IStakingP(s_Staking);
        stakings.deposit{value: ((s_stakingFee * fee) / 100)}();
        payable(s_Owner).transfer(((100 - s_stakingFee) * fee) / 100);

        emit WinnerPicked(_id, rafflesId[_id].winner);
    }

    function findWinner(
        uint256 _id,
        uint256 _number,
        uint256 tickets
    ) internal view returns (address) {
        address winner;
        for (uint256 i; i < tickets; i++) {
            if (players[_id][_number - i - 1] != payable(0x0)) {
                winner = players[_id][_number - i - 1];
                break;
            }
        }
        return winner;
    }

    function changeRafflesFee(uint256 _stakingFee) public onlyOwner {
        s_stakingFee = _stakingFee;
    }

    function refund(uint256 _id) public nonReentrant {
        Raffles memory m_Raffle = rafflesId[_id];

        if (m_Raffle.ticketsBought > 0) {
            revert TicketsAlreadyBought();
        }
        if (m_Raffle.owner != msg.sender) {
            revert NotAvailable();
        }
        uint256 funds = m_Raffle.preOrderFunds;
        delete rafflesId[_id];

        (bool success, ) = msg.sender.call{value: funds}("");
        if (!success) {
            revert("E");
        }
        if (m_Raffle.types == Type.ERC721) {
            IERC721 collection = IERC721(m_Raffle.collectionAdd);
            collection.safeTransferFrom(
                address(this),
                msg.sender,
                m_Raffle.nftId,
                ""
            );
        } else if (m_Raffle.types == Type.ERC1155) {
            IERC1155 _collection = IERC1155(m_Raffle.collectionAdd);
            _collection.safeTransferFrom(
                address(this),
                msg.sender,
                m_Raffle.nftId,
                1,
                ""
            );
        } else {
            IERC721A rCollection = IERC721A(m_Raffle.collectionAdd);
            rCollection.safeTransferFrom(
                address(this),
                msg.sender,
                m_Raffle.nftId,
                ""
            );
        }
    }

    function requestRandomWords(uint256 _id) internal {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        rafflePerRequest[s_requestId] = _id;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        numberPerRaffle[rafflePerRequest[requestId]] = randomWords[0];
        pickWinner(rafflePerRequest[requestId], randomWords[0]);
    }

    function calculateFunds(uint256 _id) internal view returns (uint256) {
        Raffles memory m_Raffle = rafflesId[_id];
        uint256 funds = m_Raffle.ticketsBought * m_Raffle.pricePerTicket;
        return funds;
    }

    function calculateFee(uint256 amount) internal pure returns (uint256) {
        uint256 funds = (amount * 2) / 100;
        return funds;
    }

    function changeFee(uint256 newFee) public onlyOwner {
        s_FEE = newFee;
    }

    function getStaking() public view returns (address) {
        return s_Staking;
    }

    function setStaking(address add) public onlyOwner {
        s_Staking = add;
    }

    function isRaffle(uint256 _id) public view returns (bool) {
        if (rafflesId[_id].endTime != 0) {
            return true;
        } else {
            return false;
        }
    }

    function setRelayer(address add) public onlyOwner {
        s_Relayer = add;
    }

    function getRaffle(uint256 _id) public view returns (Raffles memory) {
        return rafflesId[_id];
    }

    function RafflesperUser(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        return rafflesIdperUser[_owner];
    }

    function viewRaffles(uint256[] memory ids)
        public
        view
        returns (Raffles[] memory)
    {
        Raffles[] memory Raffl = new Raffles[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            Raffl[i] = rafflesId[ids[i]];
        }

        return Raffl;
    }

    function addressesPerRaffle(uint256 _id)
        public
        view
        returns (address[] memory)
    {
        address[] memory Add = new address[](realPlayersPerRaffle[_id]);

        for (uint256 i; i < realPlayersPerRaffle[_id]; i++) {
            Add[i] = addressPerPlayer[_id][i + 1];
        }

        return Add;
    }

    function ticketsPerAddreses(address[] memory _add, uint256 _id)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory Tickets = new uint256[](_add.length);

        for (uint256 i; i < _add.length; i++) {
            Tickets[i] = ticketsPerUser[_add[i]][_id];
        }

        return Tickets;
    }

    function Rafflespurchased(address _buyer)
        public
        view
        returns (uint256[] memory)
    {
        return boughtRaffles[_buyer];
    }

    function getRaffleByNft() public view returns (Raffles[] memory) {
        // lastId == last Raffle that finished

        Raffles[] memory Raffl = new Raffles[](s_ID - s_LastId);

        for (uint256 i = 0; i + s_LastId < s_ID; i++) {
            Raffl[i] = rafflesId[i + s_LastId + 1];
        }

        return Raffl;
    }

    // New Part of Contract

    function getWaitingRaffles() public view returns (uint256[] memory) {
        uint256[] memory Raffl = new uint256[](s_ID - s_LastId);

        for (uint256 i = 0; i + s_LastId < s_ID; i++) {
            if (
                ((rafflesId[i + s_LastId + 1]._state != State.Finished) &&
                    (rafflesId[i + s_LastId + 1].ticketsBought ==
                        rafflesId[i + s_LastId + 1].tickets) &&
                    (rafflesId[i + s_LastId + 1].owner != payable(0x0))) ||
                ((rafflesId[i + s_LastId + 1].endTime <= block.timestamp) &&
                    (rafflesId[i + s_LastId + 1]._state != State.Finished) &&
                    (rafflesId[i + s_LastId + 1].ticketsBought > 0))
            ) {
                Raffl[i] = (i + s_LastId + 1);
            }
        }

        return Raffl;
    }

    function requestWinners(uint256[] memory ids) public onlyRelayer {
        for (uint256 i; i < ids.length; i++) {
            requestWinner(ids[i]);
        }
    }
}
