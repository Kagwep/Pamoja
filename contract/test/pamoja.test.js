const BusinessVerificationContract = artifacts.require('BusinessVerificationContract');

contract('BusinessVerificationContract', (accounts) => {
  let owner;
  let businessOwner;
  let contract;
  let businessId;

  before(async () => {
    [owner, businessOwner] = accounts;
    contract = await BusinessVerificationContract.new({ from: owner });
  });

  it('should create a business listing', async () => {
    const businessName = 'My Business';
    const businessAddress = businessOwner;
    const fundAmountRequest = web3.utils.toWei('1', 'ether');

    await contract.createBusinessListing(businessName, businessAddress, fundAmountRequest, { from: businessOwner });

    const business = await contract.businessListings(1);
    businessId = business.businessId;

    assert.equal(business.name, businessName, 'Business name does not match');
    assert.equal(business.owner, businessOwner, 'Business owner does not match');
    assert.equal(business.businessAddress, businessAddress, 'Business address does not match');
    assert.equal(business.fundAmountRequest, fundAmountRequest, 'Fund amount request does not match');
  });

  it('should allow the contract owner to verify a business', async () => {
    const verificationFile = 'business-verification.txt';

    await contract.verifyBusiness(businessId, verificationFile, { from: owner });

    const verification = await contract.businessVerifications(businessId);

    assert.equal(verification.isVerified, true, 'Business is not verified');
    assert.equal(verification.verificationFile, verificationFile, 'Verification file does not match');
  });

  it('should allow the contract owner to create a share return agreement', async () => {
    const shareReturnAmount = web3.utils.toWei('0.5', 'ether');
    const agreementFile = 'share-agreement.txt';

    await contract.createShareReturn(businessId, shareReturnAmount, agreementFile, { from: owner });

    const shareReturn = await contract.shareReturns(businessId);

    assert.equal(shareReturn.shareReturnAmount, shareReturnAmount, 'Share return amount does not match');
    assert.equal(shareReturn.agreementFile, agreementFile, 'Agreement file does not match');
  });

  it('should allow the business owner to pay a share', async () => {
    const shareAmount = web3.utils.toWei('0.3', 'ether');

    await contract.payShare(businessId, shareAmount, { from: businessOwner });

    const business = await contract.businessListings(businessId);

    assert.equal(business.shareAmount.toString(), web3.utils.toWei('0.2', 'ether'), 'Share amount not reduced');
  });

  it('should allow the contract owner to create a pay schedule', async () => {
    const shareAmount = web3.utils.toWei('0.1', 'ether');
    const paymentDate = Math.floor(Date.now() / 1000) + 86400; // Set payment date to tomorrow

    await contract.createPaySchedule(businessId, shareAmount, paymentDate, { from: owner });

    const schedule = await contract.paySchedules(businessId);

    assert.equal(schedule.shareAmount.toString(), shareAmount, 'Share amount in the schedule does not match');
    assert.equal(schedule.paymentDate.toNumber(), paymentDate, 'Payment date in the schedule does not match');
  });

  it('should reduce share amount based on the pay schedule', async () => {
    const initialShareAmount = web3.utils.toWei('0.2', 'ether');
    const paymentDate = Math.floor(Date.now() / 1000) + 86400; // Tomorrow

    await contract.createPaySchedule(businessId, initialShareAmount, paymentDate, { from: owner });

    const schedule = await contract.paySchedules(businessId);

    assert.equal(schedule.shareAmount.toString(), initialShareAmount, 'Share amount in the schedule does not match');
    assert.equal(schedule.paymentDate.toNumber(), paymentDate, 'Payment date in the schedule does not match');

    // Wait for the payment date to pass
    const timeToWait = paymentDate - Math.floor(Date.now() / 1000);
    await new Promise(resolve => setTimeout(resolve, timeToWait * 1000));

    await contract.reduceShareBySchedule(businessId, { from: owner });

    const business = await contract.businessListings(businessId);

    assert.equal(business.shareAmount.toString(), '0', 'Share amount was not reduced as per schedule');
  });
});
