## Delete - Scenario 2 VPC

### Installing
```
git clone https://github.com/jouellnyc/AWS
```

### Usage
If you've run the create scripts via 'source $script', your shell has all the variables needed to run:
```
./delete_lb_and_vpc2.sh
```
Then Just Click Delete VPC in the GUI and all the rest will be deleted
This will take at least 11 minutes due to the waiting for dependencies

## Authors
[https://github.com/jouellnyc](mailto:jouellnyc@gmail.com)

## License
This project is licensed under the MIT License

## Acknowledgments
*Thanks AWS!*

## References
This may help if seeing errors:
https://aws.amazon.com/premiumsupport/knowledge-center/troubleshoot-dependency-error-delete-vpc/
(see list_all_aws_items.sh in this repo)
