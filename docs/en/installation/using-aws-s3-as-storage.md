# Using AWS S3 as file storage

While Moucharaka Mouwatina keeps most of its data in a PostgreSQL database, all the files such as documents or images have to be stored elsewhere.

To take care of them, Moucharaka Mouwatina uses the [Paperclip gem](https://github.com/thoughtbot/paperclip) (Warning: this gem is now deprecated and Moucharaka Mouwatina will probably migrate to ActiveStorage in the future. Check that this is not already the case before using this guide).

By default, the attachments are stored on the filesystem. However, with services such as Heroku, there is no persistent storage which means that these files are periodically erased.

This tutorial explains how to configure Paperclip to use [AWS S3](https://aws.amazon.com/fr/s3/). It doesn't recommend S3 or the use of Amazon services and will hopefully be expanded to include configuration for [fog storage](http://fog.io/storage/).

## Adding the gem _aws-sdk-s3_

First, add the following line in your _Gemfile_custom_

```ruby
gem 'aws-sdk-s3', '~> 1'
```

Make sure to have a recent version of paperclip (Moucharaka Mouwatina is currently using 5.2.1, which doesn't recognize _aws-sdk-s3_). In your Gemfile, the line should be:

```ruby
gem 'paperclip', '~> 6.1.0'
```

Run `bundle install` to apply your changes.

## Adding your credentials in _secrets.yml_

This guide will assume that you have an Amazon account configured to use S3 and that you created a bucket for your instance of Moucharaka Mouwatina. It is highly recommended to use a different bucket for each instance (production, preproduction, staging).

You will need the following information:

- the **name** of the S3 bucket
- the **region** of the S3 bucket (`eu-central-1` for UE-Francfort for example)
- the **hostname** of the S3 bucket (`s3.eu-central-1.amazonaws.com` for Francfort, for example)
- an **access key id** and a **secret access key** with read/write permission to that bucket

**WARNING:** It is recommended to create IAM users that will only have read/write permission to the bucket you want to use for that specific instance of Moucharaka Mouwatina.

Once you have these pieces of information, you can save them as environment variables of the instance running Moucharaka Mouwatina. In this tutorial, we save them respectively as _AWS_S3_BUCKET_, _AWS_S3_REGION_, _AWS_S3_HOSTNAME_, _AWS_ACCESS_KEY_ID_ and _AWS_SECRET_ACCESS_KEY_.

Add the following block in your _secrets.yml_ file:

```yaml
aws: &aws
  aws_s3_region: <%= ENV["AWS_S3_REGION"] %>
  aws_access_key_id: <%= ENV["AWS_ACCESS_KEY_ID"] %>
  aws_secret_access_key: <%= ENV["AWS_SECRET_ACCESS_KEY"] %>
  aws_s3_bucket: <%= ENV["AWS_S3_BUCKET"] %>
  aws_s3_host_name: <%= ENV["AWS_S3_HOST_NAME"] %>
```

and `<<: *aws` under the environments which you want to use S3 with, for example:

```yaml
production:
[...]
  <<: *aws
```

## Configuring Paperclip

First, activate Paperclip's URI adapter by creating the file _config/initializers/paperclip.rb_ with the following content:

```ruby
Paperclip::UriAdapter.register
```

Finally, add the following lines in the environment file of the instance which you want to use S3 with. In production, you should for example edit _config/environments/production.rb_.

```ruby
# Paperclip settings to store images and documents on S3
config.paperclip_defaults = {
  storage: :s3,
  preserve_files: true,
  s3_host_name: Rails.application.secrets.aws_s3_host_name,
  s3_protocol: :https,
  s3_credentials: {
    bucket: Rails.application.secrets.aws_s3_bucket,
    access_key_id: Rails.application.secrets.aws_access_key_id,
    secret_access_key: Rails.application.secrets.aws_secret_access_key,
    s3_region: Rails.application.secrets.aws_s3_region,
  }
}
```

You will need to restart to apply the changes.
