// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./NovaCoin.sol";
contract NovaFunding is NovaCoin {
    
    struct Campaign {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 goalAmount;
        uint256 deadline;
        uint256 amountRaised;
        bool finalized;
        mapping(address => uint256) contributions;
    }
    
    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;
    mapping(address => uint256[]) public userCampaigns;
    
    uint256 public constant REWARD_RATE = 100; // 100 NOVA токенов за 1 ETH
    
    event CampaignCreated(uint256 indexed campaignId, address indexed creator, string title, uint256 goal, uint256 deadline);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event CampaignFinalized(uint256 indexed campaignId, uint256 totalRaised, bool goalReached);
    event TokensRewarded(address indexed contributor, uint256 amount);
    
    constructor() NovaCoin(1000000) {}
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goalAmount,
        uint256 _durationDays
    ) public returns (uint256) {
        require(_goalAmount > 0, "Goal must be greater than 0");
        require(_durationDays > 0, "Duration must be greater than 0");
        require(bytes(_title).length > 0, "Title required");
        
        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        
        newCampaign.id = campaignCount;
        newCampaign.creator = msg.sender;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.goalAmount = _goalAmount;
        newCampaign.deadline = block.timestamp + (_durationDays * 1 days);
        newCampaign.amountRaised = 0;
        newCampaign.finalized = false;
        
        userCampaigns[msg.sender].push(campaignCount);
        
        emit CampaignCreated(campaignCount, msg.sender, _title, _goalAmount, newCampaign.deadline);
        
        return campaignCount;
    }
    function contribute(uint256 _campaignId) public payable {
        require(_campaignId > 0 && _campaignId <= campaignCount, "Invalid campaign");
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp < campaign.deadline, "Campaign ended");
        require(!campaign.finalized, "Campaign finalized");
        require(msg.value > 0, "Contribution must be greater than 0");
        
        campaign.contributions[msg.sender] += msg.value;
        campaign.amountRaised += msg.value;
        uint256 rewardAmount = (msg.value * REWARD_RATE) / 1 ether;
        mint(msg.sender, rewardAmount * 10 ** uint256(decimals));
        
        emit ContributionMade(_campaignId, msg.sender, msg.value);
        emit TokensRewarded(msg.sender, rewardAmount);
        emit CampaignContribution(msg.sender, msg.value, rewardAmount);
    }
    function finalizeCampaign(uint256 _campaignId) public {
        require(_campaignId > 0 && _campaignId <= campaignCount, "Invalid campaign");
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp >= campaign.deadline, "Campaign still active");
        require(!campaign.finalized, "Already finalized");
        
        campaign.finalized = true;
        bool goalReached = campaign.amountRaised >= campaign.goalAmount;
        
        if (goalReached) {
            payable(campaign.creator).transfer(campaign.amountRaised);
        }
        
        emit CampaignFinalized(_campaignId, campaign.amountRaised, goalReached);
    }
    function getCampaignDetails(uint256 _campaignId) public view returns (
        address creator,
        string memory title,
        string memory description,
        uint256 goalAmount,
        uint256 deadline,
        uint256 amountRaised,
        bool finalized
    ) {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goalAmount,
            campaign.deadline,
            campaign.amountRaised,
            campaign.finalized
        );
    }
    function getUserContribution(uint256 _campaignId, address _user) public view returns (uint256) {
        return campaigns[_campaignId].contributions[_user];
    }
    function getUserCampaigns(address _user) public view returns (uint256[] memory) {
        return userCampaigns[_user];
    }
}
