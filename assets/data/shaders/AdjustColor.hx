function setValues(hue, saturation, brightness, contrast)
{
	shader.setFloat('hue', hue);
	shader.setFloat('saturation', saturation);
	shader.setFloat('brightness', brightness);
	shader.setFloat('contrast', contrast);
}
