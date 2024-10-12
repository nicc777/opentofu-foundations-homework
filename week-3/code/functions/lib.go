package lib

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

// API Docs can be found at
// https://fiscaldata.treasury.gov/api-documentation/

const baseUrlExchangeRates = "https://api.fiscaldata.treasury.gov/services/api/fiscal_service/v1/accounting/od/rates_of_exchange"
const baseUrlCatFacts = "https://catfact.ninja/fact"

type ExchangeRateRecord struct {
	Currency     string `json:"country_currency_desc"`
	ExchangeRate string `json:"exchange_rate"`
	CreatedAt    string `json:"record_date"`
}

type Metadata struct {
	Count       int               `json:"count"`
	Labels      map[string]string `json:"labels"`
	DataTypes   map[string]string `json:"dataTypes"`
	DataFormats map[string]string `json:"dataFormats"`
	TotalCount  int               `json:"total-count"`
	Links       map[string]string `json:"links"`
}

type ExchangeRateResponse struct {
	Data     []ExchangeRateRecord `json:"data"`
	Metadata Metadata             `json:"meta"`
}

type ExchangeRateRequestOptions struct {
	Currencies string `tf:"currencies"`
}

func ExchangeRate(options ExchangeRateRequestOptions) ExchangeRateRecord {
	var response ExchangeRateResponse
	queryParams := fmt.Sprintf("fields=country_currency_desc,exchange_rate,record_date&filter=country_currency_desc:in:(%s),record_date:gte:2020-01-01&sort=-record_date&page[size]=1", options.Currencies)
	requestUrl := fmt.Sprintf("%s?%s", baseUrlExchangeRates, queryParams)
	resp, err := http.Get(requestUrl)

	if err != nil {
		log.Fatal(err)
	}

	body, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		log.Fatal(err)
	}

	err = json.Unmarshal(body, &response)

	if err != nil {
		log.Fatal(err)
	}

	return response.Data[0]
}

type CatFactRecord struct {
	Fact   string `json:"fact"`
	Length int32  `json:"length"`
}

type CatFactResponse struct {
	Fact string `json:"fact"`
}

type CatFactRequestOptions struct {
	MaxLength string `tf:"max_length"`
}

func CatFact(options CatFactRequestOptions) CatFactResponse {
	var response CatFactResponse
	queryParams := fmt.Sprintf("max_length=%s", options.MaxLength)
	requestUrl := fmt.Sprintf("%s?%s", baseUrlCatFacts, queryParams)
	resp, err := http.Get(requestUrl)

	if err != nil {
		log.Fatal(err)
	}

	body, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		log.Fatal(err)
	}

	err = json.Unmarshal(body, &response)

	if err != nil {
		log.Fatal(err)
	}

	return response
}
