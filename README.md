# Cloud Resume Challenge
## Overview
This project is an implementation of Forrest Brazeal's [Cloud Resume Challenge](https://cloudresumechallenge.dev/), which is designed to give participants experience with various cloud/development technologies like serverless, front/back end development, IAC, CICD, monitoring, CDNs, Databases, etc. The main challenge of the Cloud Resume Challenge is to deploy a website on the cloud provider of choice by using managed infrastructure. In the case of this implementation, I have deployed a website that displays my resume with a built-in visitor counter as well as a blog post about the site's development. The website is deployed using various AWS technologies like: S3 Static Hosting, CloudFront CDN, API Gateway, DynamoDB, Route 53, IAM, AWS Certificate Manager, Lambda, and AWS WAF. Importantly, the website and nearly all associated infrastructure are deployed using IAC (Terraform) in a CI/CD format (GitHub Actions). The only components not deployed with Terraform are: the AWS Account, the IAM OIDC IDP that establishes trust between GitHub and AWS, the Route 53 Hosted Zone, the IAM Role assumed by GitHub, and the S3 Bucket/Dynamo DB table used to store Terraform Remote State.

## Project Structure 
Here I will go through each of the folders in this repository, and briefly discuss their importance/usage.
- .github: This folder contains all GitHub Actions workflows. The important workflows to be aware of are 'tf-build-DEV.yml', 'tf-build-PROD.yml', and 'tf-destroy-BOTH-RETRY-MANUAL.yml'. The build workflows are configured to run on push events where certain files change. 
    - tf-build-DEV.yml: If relevent files change on a push to the 'Test' branch, this workflow will run. First, it will configure AWS short-term credentials using the AWS-GitHub OIDC trust that was established manually using the **aws-actions/configure-aws-credentials** action. Then it will run Terraform init, validate, plan, and apply. After a successful Terraform apply it will run web/API tests using Cypress Front-End Testing. If the tests are successful, then a Pull Request is created to merge the 'Test' branch into the 'main' branch. If the tests are failed, then an Issue is created with the 'bug' label to indicate an issue.
    - tf-build-PROD.yml: If relevent files change on a push to the 'main' branch, this workflow will run. First, it will configure AWS short-term credentials using the AWS-GitHub OIDC trust that was established manually using the **aws-actions/configure-aws-credentials** action. Then it will run Terraform init, validate, plan, and apply. If Terraform apply fails, then an Issue is created with the 'bug' label to indicate an issue.
    - tf-destroy-BOTH-RETRY-MANUAL.yml: This can only be run manually (ie. workflow_dispatch). If it is ran in the 'Test' branch, then it will run the Terraform Destroy commands against the infrastructure stood up by the 'tf-build-DEV.yml'. If it is ran in the 'main' branch, then it will run the Terraform Destroy commands against the infrastructure stood up by the 'tf-build-PROD.yml'. If it is ran anywhere else, nothing will happen. This workflow uses the **nick-fields/retry** action to retry the terraform destroy command after 30 minutes in the event that it gets stalled and doesn't complete. 
- cypresstests: This folder contains the ENTIRE Cypress project for testing the deployed website. I am not incredibly familiar with the Cypress software, so I ended up putting all the required project files in the GitHub repo. There may be a better way to do this, but for now it is required. The important files are: 'cypress.env.json' (holds Cypress environment variables) and 'resumesitetesting.cy.js' (the actual Cypress test specification). 'resumesitetesting.cy.js' is the actual test definition file, and can be modified to add in more testing.
- tf-be/tf-fe/tf-main: These folders each contain a separate Terraform module.
    - tf-fe: This folder contains a Terraform module that, when run, will deploy: S3 Bucket and required configurations, S3 Bucket Policy, S3 Objects (the actual website files), ACM Certificate (for the site), WAF WebACL, CloudFront Distribution, and a Route 53 Alias A Record. 
    - tf-be: This folder contains a Terraform module that, when run, will deploy: DynamoDB Table, IAM Role and Policy (Lambda Execution Role), Lambda Function, WAF WebACL, and API Gateway REST API.
    - The only dependency between tf-fe and tf-be is that tf-fe depends on the API Gateway REST API URL produced by tf-be.
    - tf-main: This folder contains the root Terraform module that deploys both the tf-fe and tf-be modules. When terraform destroy/apply is called by the GitHub Actions workflows, they are called from this folder. 
- web-be: This folder strictly contains the lambda function that is deployed and integrated with the API Gateway REST API and makes calls to the DynamoDB table. On a 'terraform apply' call, the python file in this folder is zipped up and uploaded to Lambda. In the future, this folder will be used for general backend web resources.
    - The **SetVisitorCounter_Lambda.py** Lambda function gets called by the API Gateway REST API using the Lambda Proxy Integration. The entire web request is parsed by the Lambda function, which extracts out the Source IP. It hashes the Source IP and does a lookup in the DDB Table for the IP hash. If it is not present, then this is a unique visitor and the hash is added to the table along with the current timestamp. If it is present, then this visitor has visited the site before - it does an additional check to see if the vistor's 'visit timestamp' in the table is longer than 2 weeks ago. If the visit is longer than 2 weeks ago, then the visit counts as a unique visit and the 'visit timestamp' is set to the current timestamp. Ultimately, at the end of each invocation, the Lambda function returns the current unique visitor count which is displayed on the website which called it.
- web-fe: This folder contains the html and js files used to create the website front end.  On a 'terraform apply' call, the relevant html and js files are uploaded to the dynamically created S3 Bucket. In the future, this will contain any additional html, css, or js files.
    - The 'index.js' file runs on load of any web page in the static site. When it runs it simply calls the API Gateway API base URL, which proxies the request to the Lambda function, which returns the current unique visitor count value, and sets the Visitor Counter field in the loaded html file. 


## Technical Overview 
This project is made up of a web front-end and a serverless backend.
Flow of traffic: User navigates to a configurable URL in the browser - this URL is a R53 Alias A record to the deployed CloudFront Distribution. The CloudFront Distribution has an HTTP Origin (S3 Static Site) that it sends all traffic to. The S3 Static site is composed of 1 or more HTML files and a JS file that makes dynamic API calls as the HTML files load. Once the user's browser loads the S3 Static Site, the JS makes a call to an API Gateway REST API which proxies the request to a Lambda function. The Lambda function does some checks on whether the Source IP and time since last visit constitute whether this visit is unique. If the visit is unique, the visitor information is stored in the Dynamo DB table and the unique visitor count value (which is also stored in the DDB table) is incremented. Ultimately, the Lambda function fetches the latest unique visitor count value and returns it. The JS script receives the vistor count value and updates the HTML file with the value. 

## Usage 
To deploy the infrastructure, you must first make sure all the GitHub Repository variables are filled out correctly. Values that must be filled out:
- AWS_HOSTEDZONE_DEV: the hosted zone in the Dev AWS tenant that will be used for the Route 53 alias A record to the CloudFront Distribution
- AWS_HOSTEDZONE_PROD: the hosted zone in the Prod AWS tenant that will be used for the Route 53 alias A record to the CloudFront Distribution
- AWS_ROLE_DEV: the role in the AWS Dev tenant that the GitHub Actions workflows will assume when performing terraform operations
- AWS_ROLE_PROD: the role in the AWS Prod tenant that the GitHub Actions workflows will assume when performing terraform operations
- AWS_SITENAME: the name of the site that you want for your Dev and Prod tenants. The URL of the site will ultimately be **AWS_SITENAME.AWS_HOSTEDZONE_PROD/DEV**
- TF_STATE_BUCKET_DEV: the name of the S3 bucket that will be used to store Terraform's remote state for the Dev deployment
- TF_STATE_BUCKET_PROD: the name of the S3 bucket that will be used to store Terraform's remote state for the Prod deployment
- TF_STATE_DDBTABLE_DEV: the name of the Dynamo DB Table that will be used to lock Terraform's remote state for the Dev deployment
- TF_STATE_DDBTABLE_PROD: the name of the Dynamo DB Table that will be used to lock Terraform's remote state for the Prod deployment
- TF_STATE_KEY_DEV: the name of the S3 Object that will hold Terraform's remote state for the Dev deployment
- TF_STATE_KEY_PROD: the name of the S3 Object that will hold Terraform's remote state for the Prod deployment
- TF_STATE_REGION: The region of the DynamoDB Table and S3 Bucket used for Terraform Remote State. This should be the same for Prod and Dev



## Issues to be aware of
- Don't change Some Github Repo variables while an environment is stood up. (Need to think about this more)
  - Wouldn't this not matter. If you changed the variables for an existing environment, terraform apply would change the resources. Terraform destory doesn't actually care about the value of input variables.
  - WHAT WOULD MATTER, is iif you change any of the STATE variable values. 



Mention: Least Privilege, Cypress Testing

