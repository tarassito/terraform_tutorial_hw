### Function as a service Project

#### Description
Project consists of HTTP-triggered Function which ingests event to Kinesis data stream. 
From there data is stored in S3 bucket as json file. 

#### Deployment

##### Prerequisites
- Terraform installed
- AWS account and credentials that allow you to create resources. 
- [Optional] AWS CLI installed if you want to send requests to Lambda through AWS CLI.

##### Steps
1. Clone the repository - https://github.com/tarassito/terraform_tutorial_hw.git
2. Login to AWS account and create S3 bucket. Update bucket name in 
`project/variables.tf` (variable "bucket_name" , field default) with name of just created bucket. 
3. Run `terraform init` from `project` directory. 
4. Run `terraform plan` and `terraform apply`. 
5. In outputs result you will see lambda_function_url. Save it for future Lambda invoking.
6. Congrats project is deployed.

#### How to interact with system

1. To trigger http_to_kinesis lambda send `POST` request to lambda_function_url with such data 
structure - `{"id": "1","text": "some text here", "date": "13-04-2023"}`. 
`id` and `date` are required fields.

2. Function can't be invoked without AWS credentials. You might use Postman with AWS Signature 
or send request in AWS CLI. 

3. After request is send check S3 bucket, json file should be there. 