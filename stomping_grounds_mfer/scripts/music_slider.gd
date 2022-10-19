extends HSlider

func save():
	var save_dict = {
		"name": get_name(),
		"value" : value
	}
	return save_dict;
