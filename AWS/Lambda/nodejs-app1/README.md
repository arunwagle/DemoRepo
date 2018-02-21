Created a user and setup permissions for Lambda, RDS etc

# Default created in us-east-2
aws rds create-db-instance \
    --region us-east-1 \
    --db-instance-identifier MySQLForLambdaTest \
    --db-instance-class db.t2.micro \
    --engine MySQL \
    --allocated-storage 5 \
    --no-publicly-accessible \
    --db-name ExampleDB \
    --master-username admin123 \
    --master-user-password admin123 \
    --backup-retention-period 3

Note Endpoint from AWS console : mysqlforlambdatest.czi28ocim3ji.us-east-2.rds.amazonaws.com

### Create deployment packages
https://docs.aws.amazon.com/lambda/latest/dg/with-s3-example-deployment-pkg.html#with-s3-example-deployment-pkg-python

#Creation of virtualenv:
virtualenv -p python3 ~/shrink_venv

# Run virtual virtualenv
source ~/shrink_venv/bin/activate

deactivate

pip install Pillow
pip install boto3
pip install pymysql

#Create deployment zip file
cd $VIRTUAL_ENV/lib/python3.6/site-packages/
zip -r9 /Users/arunwagle/Projects/DemoRepo/AWS/Lambda/python-mysql/python-mysql.zip *

cd /Users/arunwagle/Projects/DemoRepo/AWS/Lambda/python-mysql
zip -g python-mysql.zip *.py

# Create a role in IAM
Login to https://console.aws.amazon.com/iam/
Create role with name Role_For_Lambda with  Policy=AWSLambdaRole  & AWSLambdaVPCAccessExecutionRole

Note down:
Role ARN:
arn:aws:iam::776262733296:role/Role_For_Lambda

# Create function

aws lambda create-function \
--region us-east-1 \
--function-name   CreateTableAddRecordsAndRead  \
--zip-file fileb:///Users/arunwagle/Projects/DemoRepo/AWS/Lambda/python-mysql/python-mysql.zip \
--role arn:aws:iam::776262733296:role/Role_For_Lambda \
--handler app.handler \
--runtime python3.6 \
--vpc-config SubnetIds=subnet-d6c7e6eb,subnet-bf0b71da,subnet-7d67f771,subnet-70b2c15a,subnet-895729d1,subnet-23062455,SecurityGroupIds=sg-648f2e1f

# Update
aws lambda update-function-code \
--region us-east-1 \
--function-name   CreateTableAddRecordsAndRead  \
--zip-file fileb:///Users/arunwagle/Projects/DemoRepo/AWS/Lambda/python-mysql/python-mysql.zip \
--publish



aws lambda invoke \
--function-name CreateTableAddRecordsAndRead  \
--region us-east-1 \
output.txt  
