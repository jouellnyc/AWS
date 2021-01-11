#!/usr/bin/env python3


from alpha_vantage.fundamentaldata import FundamentalData

fd = FundamentalData(key="XCLK59G68DQR3EFM", output_format="pandas")

print(fd.get_income_statement_annual("LMND"))
