# GKE Batch and AI/ML recipes

## Summary

This repository contains samples and in-progress content intended to be merged into the officially supported GKE samples.

## Usage
Each Batch and AI/ML sample will be based on an infrastructure pattern layed out in the `base` directory. Simply copy the content in `base` to a working directory inside `batch` or `aiml` and begin adding customization for the related sample content.

In your working directory, replace the value of `YOUR_GCS_BUCKET_NAME` in `backend.tf` to a GCS bucket that you have created to host the state information from Terraform.


## Contribution

Please feel free to open pull requests against `main`, all contributions welcome.