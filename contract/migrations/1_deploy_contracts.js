const ConvertLib = artifacts.require("Pamoja");


module.exports = function(deployer) {
  
  deployer.deploy(Pamoja).then((instance) => {
    console.log("Pamoja contract deployed at adress:",instance.address)
  });
  
};
