/*{
	"DESCRIPTION": "exported jitter gen patch",
	"CREDIT": "gen-C74",
	"CATEGORIES": [
		"GEN FX"
	],
	"INPUTS": [
		{
			"NAME": "bipolar",
			"TYPE": "float",
			"DEFAULT": 0.0
		}
		,
		{
			"NAME": "bypass_gate",
			"TYPE": "float",
			"DEFAULT": 0.0
		}
		,
		{
			"NAME": "tin1",
			"TYPE": "image"
		},
		{
			"NAME": "tin2",
			"TYPE": "image"
		},
		{
			"NAME": "tin3",
			"TYPE": "image"
		}
	]
}*/
/*
Copyright (c) 2023 Cycling '74

The code that Max generates automatically and that end users are capable of
exporting and using, and any associated documentation files (the “Software”)
is a work of authorship for which Cycling '74 is the author and owner for
copyright purposes.

This Software is dual-licensed either under the terms of the Cycling '74
License for Max-Generated Code for Export, or alternatively under the terms
of the General Public License (GPL) Version 3. You may use the Software
according to either of these licenses as it is most appropriate for your
project on a case-by-case basis (proprietary or not).

A) Cycling '74 License for Max-Generated Code for Export

A license is hereby granted, free of charge, to any person obtaining a copy
of the Software (“Licensee”) to use, copy, modify, merge, publish, and
distribute copies of the Software, and to permit persons to whom the Software
is furnished to do so, subject to the following conditions:

The Software is licensed to Licensee for all uses that do not include the sale,
sublicensing, or commercial distribution of software that incorporates this
source code. This means that the Licensee is free to use this software for
educational, research, and prototyping purposes, to create musical or other
creative works with software that incorporates this source code, or any other
use that does not constitute selling software that makes use of this source
code. Commercial distribution also includes the packaging of free software with
other paid software, hardware, or software-provided commercial services.

For entities with UNDER $200k in annual revenue or funding, a license is hereby
granted, free of charge, for the sale, sublicensing, or commercial distribution
of software that incorporates this source code, for as long as the entity's
annual revenue remains below $200k annual revenue or funding.

For entities with OVER $200k in annual revenue or funding interested in the
sale, sublicensing, or commercial distribution of software that incorporates
this source code, please send inquiries to licensing (at) cycling74.com.

The above copyright notice and this license shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Please see
https://support.cycling74.com/hc/en-us/articles/360050779193-Gen-Code-Export-Licensing-FAQ
for additional information

B) General Public License Version 3 (GPLv3)
Details of the GPLv3 license can be found at: https://www.gnu.org/licenses/gpl-3.0.html    

*/
#define hypot(x, y) sqrt(x*x+y*y)
#define xor(x, y)	((!(x&&y))&&(x||y))
#define sinh(x)		(0.5*(exp(x) - exp(-x)))
#define cosh(x)		(0.5*(exp(x) + exp(-x)))
#define tanh(x)		((sinh(x))/(cosh(x)))
#define asinh(x)	(log(x) + sqrt(x*x+1.))
#define acosh(x)	(log(x) + sqrt(x*x-1.))
#define atanh(x)	(0.5*log((1.+x)/(1.-x)))
#define trunc(x)	(vec4(x.r > 0. ? floor(x.r) : ceil(x.r), x.g > 0. ? floor(x.g) : ceil(x.g), x.b > 0. ? floor(x.b) : ceil(x.b), x.a > 0. ? floor(x.a) : ceil(x.a)))

vec2 jit_wrap1(vec2 v) {
	return mod(v, 1.);
}

vec2 jit_clamp1(vec2 v) {
	return clamp(v, 0., 1.);
}

vec2 jit_mirror1(vec2 v) {
	return 1.-abs((mod(v, 2.)-1.));
}








void main() {
	vec4 in1 = IMG_NORM_PIXEL(tin1, isf_FragNormCoord);
	vec4 in2 = IMG_NORM_PIXEL(tin2, isf_FragNormCoord);
	vec4 in3 = IMG_NORM_PIXEL(tin3, isf_FragNormCoord);
	vec2 norm = isf_FragNormCoord;
	
	
	
	
	gl_FragColor = vec4(0.0);
	gl_FragColor = vec4(0.0);
	float r = (IMG_NORM_PIXEL(tin1, jit_wrap1(norm)).r);
	float g = (IMG_NORM_PIXEL(tin1, jit_wrap1(norm)).g);
	float r_out = (mix(r, r * 2.0 - 1.0, bipolar));
	float g_out = (mix(g, g * 2.0 - 1.0, bipolar));
	vec4 x_ch = (vec4(r_out, r_out, r_out, 1.0));
	vec4 y_ch = (vec4(g_out, g_out, g_out, 1.0));
	vec4 tmp_expr_6 = (mix(x_ch, IMG_NORM_PIXEL(tin1, jit_wrap1(norm)), bypass_gate));
	vec4 tmp_expr_7 = (mix(y_ch, IMG_NORM_PIXEL(tin1, jit_wrap1(norm)), bypass_gate));
	gl_FragColor = tmp_expr_6;
	gl_FragColor = tmp_expr_7;
}

