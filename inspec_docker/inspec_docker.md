# Inspec for Docker 
Documentation on how to Install and use Inspec for Docker.

**NOTE:**<br>
 - **Donot install the Inspec Framework directly or using the ruby gems as these versions of Inspec would need further Plugins and configuration to detect the docker containers.**
 - All Inspec Tests are directiory structure sensitive.
 - More information on how to run the docker container before Inspec test can br found [here.](https://gitlab.freudenberg-it.com/itmall/devops-salt-container/blob/master/README.md)

### Step 1: Installation <br>
 Install the ChefDk package and Inspec using the following curl command <br> (Configure the necessary Proxy Settings)
 
 `curl -L https://omnitruck.chef.io/install.sh | bash -s -- -P inspec`
 <br>
 
  
 

 
 ### Step 2: Running Inspec Test
 
1. Create a test profile in Inspec.   (Sample Inspec Test [Here](https://www.inspec.io/docs/reference/resources/service/))
2. save the file as a regular RUBY file. (*test.rb* here)
3. Run the docker container if not already running.
4. Use the following cmd to run Inspec Test against the docker container.

`inspec exec test.rb -t docker://CONTAINER ID`

This should return the test summary with success and failures.



### TroubleShooting and Useful commands

- For CONTAINER ID use the command
`docker ps`

- To check Inspec Environment
`inspec env`

- To troubleshoot the Inspec Path
`inspec exec PATHS --diagnose`

- To verify the installation of Inspec 
`inspec --version`

- To access the Inspec Shell directly
`inspec shell`

### Useful Links
You can find the related documentation for ChefDk [here.](https://docs.chef.io/install_omnibus.html)<br>
You can find the related documentation for Inspec [here.](https://www.inspec.io/docs/)<br>
https://discourse.chef.io/t/resolved-download-latest-version-of-inspec-on-linux/13770 <br>


 