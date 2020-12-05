# Introduction 
The aim of this repository is to strealine the process of deploying a Windows Virtual Desktop infrastructure. As well to publish artifacts required to it.

# Getting Started
TODO: Below are the steps to take into account.
1.	Image creation
2.  Active directory objects provisioning
3.	Azure AD Objects sync 
4.  Storage acccount creationg and domain join process
5.	Windows Virtual Desktop deployment

# Build and Test
TODO: Describe and show how to build your code and run the tests. 
---
1.	Image creation 

This is the most time consuming part of the deployment. At a high level all you need is a working image with all the required software that the WVD will be providing to the end users.

As we are using FSlogix for profile container the image also requires the FSLogix to be installed and configured.

- Create the windows based image
- Install any LOB software
- Install FSLOGIX 
- Run the sysprep and capture the image.
- Make it avaialable in azure

2.  Active directory objects provisioning

At this stage you already have access to a domain contoller and you kinda need to create the required Security Groups and Organizational UNITS

-  Choose where the servers are going to be placed and create the OU
-  Create the Security Groups and assigned the users to it. 
-  Create the group policies for FSlogix

3.	Azure AD Objects sync 

This step is just for you to make sure the security groups were created successfully and the User security groups are synced into AAD.

4.  Storage acccount creationg and domain join process

Make use  of DeployWVD-StorageAccount.ps1 that has a walk through the process of creating the storage account and joining it to AD.

Please note that this needs to be done on a domain joined machine that has Domain admin permissions

5.	Windows Virtual Desktop deployment

This is where the fun begins. There is template enclosed to this project but you can use the portal to do it.

# Trobleshooting
- Fslogix Trobleshooting

Have a look at the logs

- Gpo Trobleshooting

Make sure the GPO has been applied 
Run the gpupdate /force
run the gpresult /h 

- Permissions trobleshooting


# References
TODO: Links and references about the technology


- [A nice walkthrough the latest around WVD](https://www.christiaanbrinkhoff.com/2020/05/01/windows-virtual-desktop-technical-2020-spring-update-arm-based-model-deployment-walkthrough/
)

If you want to learn more about creating good readme files then refer the following [guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-a-readme?view=azure-devops). You can also seek inspiration from the below readme files:
