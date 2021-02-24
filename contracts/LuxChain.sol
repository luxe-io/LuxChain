pragma solidity ^0.4.18;

contract LuxChain {

    string contractName;
    string contractSymbol;
    uint256 totalSupply;
    uint256 donated;
    address creator;

    struct Asset {
        address owner;
        bool stolen;
        bool found;
        string foundDetails;
        string ipfsHash;
    }

    // Switch to turn company admin off or on
    bool adminSwitch;

    // Price to register Asset in Wei
    uint registrationPrice;

    mapping(address => bool) company;
    mapping(string => Asset) register; // Maps assetNumber to Asset
    mapping(address => string[]) ownerList; // Maps address to asset numbers
    mapping(string => address) approvedAddress; // Maps asset number to address which is approved to take ownership
    mapping(address => bool) public coupon;

    function giveCoupon(address _to) onlyCompany public {
        coupon[_to] = true;
    }

    function takeCoupon(address _to) onlyCompany public {
        delete coupon[_to];
    }

    function useCoupon() internal {
        coupon[msg.sender] = false;
    }

    modifier onlyAdmin(){
        if (adminSwitch) require(company[msg.sender]);
        _;
    }

    modifier onlyAdminOrOwner(string _assetNumber){
        require((adminSwitch && (company[msg.sender])) || register[_assetNumber].owner == msg.sender);
        _;
    }

    modifier onlyCompany(){
        require(company[msg.sender]);
        _;
    }

    modifier onlyCompanyOrOwner(string _assetNumber){
        require(company[msg.sender] || (register[_assetNumber].owner == msg.sender));
        _;
    }

    modifier onlyContractCreator(){
        require(msg.sender == creator);
        _;
    }

    modifier AssetOwner(string _assetNumber){
        require(register[_assetNumber].owner == msg.sender);
        _;
    }

    modifier hasApproval(string _assetNumber){
        require(approvedAddress[_assetNumber] == msg.sender);
        _;
    }

    modifier costs(uint _price) {
        require(msg.value >= _price);
        _;
    }

    event Approval(address owner, address to, string assetNumber);
    event AssetCreated(string assetNumber);
    event AssetRemoved(address company, address owner, string assetNumber);
    event AssetTransferred(address from, address to, string assetNumber);
    event AssetStolen(string assetNumber, string details);
    event AssetFound(address finder, string assetNumber);
    event AssetNotFound(address finder, string assetNumber);
    event AssetReturned(address owner, string assetNumber);
    event CompanyAdded(address admin, address company);
    event CompanyRemoved(address admin, address company);
    event OwnerChanged(address from, address to);
    event EtherWithdrawn(address from, address to, uint value);
    event AdminSwitchChanged(bool status);

    function LuxChain() public {
        creator = msg.sender;
        registrationPrice = 1000;
        adminSwitch = false;
        contractName = "Lux-Token";
        contractSymbol = "LUX";
        totalSupply = 0;
    }

    function getSender() constant public returns (address){
        return msg.sender;
    }

    function getEthBalance() constant public returns (uint) {return address(this).balance;}

    function name() constant public returns (string){
        return contractName;
    }

    function symbol() constant public returns (string){
        return contractSymbol;
    }

    function getTotalSupply() constant public returns (uint256){
        return totalSupply;
    }

    function balanceOf(address _owner) constant public returns (uint256){
        return ownerList[_owner].length;
    }

    function ownerOf(string _assetNumber) constant public returns (address){
        require(register[_assetNumber].owner != 0);
        return register[_assetNumber].owner;
    }

    function approve(address _to, string _assetNumber) AssetOwner(_assetNumber) public {
        approvedAddress[_assetNumber] = _to;
        emit Approval(msg.sender, _to, _assetNumber);
    }

    function takeOwnership(string _assetNumber) hasApproval(_assetNumber) public {
        address oldOwner = register[_assetNumber].owner;
        ownerList[msg.sender].push(_assetNumber);
        register[_assetNumber].owner = msg.sender;
        string[] storage fn = ownerList[oldOwner];
        uint index = getAssetIndex(oldOwner, _assetNumber);
        for (uint i = index; i < fn.length - 1; i++) {
            fn[i] = fn[i + 1];
        }
        delete fn[fn.length - 1];
        fn.length--;

        emit AssetTransferred(oldOwner, msg.sender, _assetNumber);
    }

    function transfer(address _to, string _assetNumber) AssetOwner(_assetNumber) public {
        require(_to != 0);
        ownerList[_to].push(_assetNumber);
        register[_assetNumber].owner = _to;
        string[] storage fn = ownerList[msg.sender];
        uint index = getAssetIndex(msg.sender, _assetNumber);
        for (uint i = index; i < fn.length - 1; i++) {
            fn[i] = fn[i + 1];
        }
        delete fn[fn.length - 1];
        fn.length--;

        emit AssetTransferred(msg.sender, _to, _assetNumber);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) constant public returns (string assetNumber){
        require(_index < balanceOf(_owner));
        require(_index >= 0);
        assetNumber = ownerList[_owner][_index];
    }

    function tokenMetadata(string _assetNumber) constant public returns (string){
        return register[_assetNumber].ipfsHash;
    }

    function updateTokenMetadata(string _assetNumber, string _ipfsHash) AssetOwner(_assetNumber) public {
        register[_assetNumber].ipfsHash = _ipfsHash;
    }

    function() payable public {
        donated = donated + msg.value;
        // Can remove this
    }

    function withdrawEther(address _to, uint _value) onlyContractCreator() public {
        _to.transfer(_value);
        emit EtherWithdrawn(msg.sender, _to, _value);
    }

    function addAsset(string _assetNumber) payable onlyContractCreator costs(registrationPrice) public {
        require(register[_assetNumber].owner == 0);
        // Check Asset isn't owned
        Asset storage b = register[_assetNumber];
        b.owner = msg.sender;
        b.stolen = false;
        b.found = false;
        b.foundDetails = "";
        totalSupply++;
        donated = donated + msg.value;
        emit AssetCreated(_assetNumber);
        ownerList[msg.sender].push(_assetNumber);
    }

    function addCompany(address _companyAdd) onlyContractCreator public {
        company[_companyAdd] = true;
        emit CompanyAdded(creator, _companyAdd);
    }

    function reportStolen(string _assetNumber, string _ipfsHash) AssetOwner(_assetNumber) public {
        Asset storage b = register[_assetNumber];
        b.stolen = true;
        b.ipfsHash = _ipfsHash;
        emit AssetStolen(_assetNumber, _ipfsHash);
    }

    function reportFound(string _assetNumber, string _details) public {
        require(register[_assetNumber].stolen);
        Asset storage b = register[_assetNumber];
        b.found = true;
        b.foundDetails = _details;
        emit AssetFound(msg.sender, _assetNumber);
    }

    function reportNotFound(string _assetNumber) AssetOwner(_assetNumber) public {
        register[_assetNumber].found = false;
        register[_assetNumber].foundDetails = "";
        emit AssetNotFound(msg.sender, _assetNumber);
    }

    function reportReturned(string _assetNumber) AssetOwner(_assetNumber) public {
        require(register[_assetNumber].stolen);
        require(register[_assetNumber].found);
        Asset storage b = register[_assetNumber];
        b.stolen = false;
        b.found = false;
        b.foundDetails = "";
        emit AssetReturned(msg.sender, _assetNumber);
    }

    function transferOwner(string _assetNumber, address _newOwner) onlyAdminOrOwner(_assetNumber) public {
        require(_newOwner != 0);
        ownerList[_newOwner].push(_assetNumber);
        register[_assetNumber].owner = _newOwner;
        string[] storage fn = ownerList[msg.sender];
        uint index = getAssetIndex(msg.sender, _assetNumber);
        for (uint i = index; i < fn.length - 1; i++) {
            fn[i] = fn[i + 1];
        }
        delete fn[fn.length - 1];
        fn.length--;

        emit AssetTransferred(msg.sender, _newOwner, _assetNumber);
    }

    function removeAsset(string _assetNumber) onlyAdminOrOwner(_assetNumber) public {
        address owner = register[_assetNumber].owner;
        delete register[_assetNumber];
        string[] storage fn = ownerList[owner];
        uint index = getAssetIndex(owner, _assetNumber);
        for (uint i = index; i < fn.length - 1; i++) {
            fn[i] = fn[i + 1];
        }
        delete fn[fn.length - 1];
        fn.length--;
        totalSupply--;

        emit AssetRemoved(msg.sender, owner, _assetNumber);
    }

    // Only contract creator can remove companies
    function removeCompany(address _companyAdd) onlyContractCreator public {
        require(company[_companyAdd]);
        delete company[_companyAdd];
        emit CompanyRemoved(msg.sender, _companyAdd);
    }

    function changeOwner(address _newOwner) onlyContractCreator public {
        creator = _newOwner;
        emit OwnerChanged(msg.sender, _newOwner);
    }

    function changeAdminSwitch(bool _status) public onlyContractCreator returns (bool){
        adminSwitch = _status;
        emit AdminSwitchChanged(_status);
        return adminSwitch;
    }

    // Get functions
    function getAsset(string _assetNumber) constant public
    returns (address owner, string details, bool stolen, bool found, string ipfsHash){

        Asset storage b = register[_assetNumber];
        owner = b.owner;
        details = b.foundDetails;
        stolen = b.stolen;
        found = b.found;
        ipfsHash = b.ipfsHash;
    }

    function getAssetIndex(address _owner, string _assetNumber) constant public returns (uint i){
        string[] storage fn = ownerList[_owner];
        for (i = 0; i < fn.length; i++) {
            if (keccak256(abi.encode(fn[i])) == keccak256(abi.encode(_assetNumber))) return i;
        }
        require(false);
        // Fail if not found
    }

    function getassetNumber(address _owner, uint _index) constant public returns (string assetNumber){
        require(_index < ownerList[_owner].length);
        assetNumber = ownerList[_owner][_index];
    }

    function isCompany(address _companyAdd) constant public returns (bool){
        return company[_companyAdd];
    }

    function getEthDonated() constant public returns (uint) {return donated;}

    function getAdminSwitch() constant public returns (bool) {return adminSwitch;}

    function getRegistrationPrice() constant public returns (uint)
    {return registrationPrice;}
}
