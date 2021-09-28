package model

// Product example
type Product struct {
	Name string `json:"name" example:"banana"`
	Id   uint64 `json:"id" example:"123456"`
}

var Products = []Product{
	{Id: 123456, Name: "banana"},
	{Id: 999999, Name: "apple"},
	{Id: 621000, Name: "tangerine"},
}
