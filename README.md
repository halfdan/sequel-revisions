# Sequel History

This plugin provides an easy way to track changes to your model. It currently only supports PostgreSQL as it uses a JSON field to store changed fields.

## Requirements

This plugins requires a `_history` table for each model you want to track. Using polymorphism is discouraged by Sequel as it shows bad performance, especially for large collections. 
