define("dojox/encoding/digests/SHA512", ["./_sha-64"], function(sha64){
	//	The 512-bit implementation of SHA-2
	
	//	Note that for 64-bit hashes, we're actually doing high-order, low-order, high-order, low-order.
	//	The 64-bit functions will assemble them into actual 64-bit "words".
	var hash = [
		0x6a09e667, 0xf3bcc908, 0xbb67ae85, 0x84caa73b, 0x3c6ef372, 0xfe94f82b, 0xa54ff53a, 0x5f1d36f1,
		0x510e527f, 0xade682d1, 0x9b05688c, 0x2b3e6c1f, 0x1f83d9ab, 0xfb41bd6b, 0x5be0cd19, 0x137e2179
	];

	//	the exported function
	var SHA512 = function(/* String */data, /* sha64.outputTypes? */outputType){
		var out = outputType || sha64.outputTypes.Base64;
		data = sha64.stringToUtf8(data);
		var wa = sha64.digest(sha64.toWord(data), data.length * 8, hash, 512);
		switch(out){
			case sha64.outputTypes.Raw: {
				return wa;
			}
			case sha64.outputTypes.Hex: {
				return sha64.toHex(wa);
			}
			case sha64.outputTypes.String: {
				return sha64._toString(wa);
			}
			default: {
				return sha64.toBase64(wa);
			}
		}
	};
	SHA512._hmac = function(/* string */data, /* string */key, /* sha64.outputTypes? */outputType){
		var out = outputType || sha64.outputTypes.Base64;
		data = sha64.stringToUtf8(data);
		key = sha64.stringToUtf8(key);

		//	prepare the key
		var wa = sha64.toWord(key);
		if(wa.length > 16){
			wa = sha64.digest(wa, key.length * 8, hash, 512);
		}

		//	set up the pads
		var ipad = new Array(16), opad = new Array(16);
		for(var i=0; i<16; i++){
			ipad[i] = wa[i] ^ 0x36363636;
			opad[i] = wa[i] ^ 0x5c5c5c5c;
		}

		//	make the final digest
		var r1 = sha64.digest(ipad.concat(sha64.toWord(data)), 512 + data.length * 8, hash, 512);
		var r2 = sha64.digest(opad.concat(r1), 512 + 160, hash, 512);

		//	return the output.
		switch(out){
			case sha64.outputTypes.Raw: {
				return wa;
			}
			case sha64.outputTypes.Hex: {
				return sha64.toHex(wa);
			}
			case sha64.outputTypes.String: {
				return sha64._toString(wa);
			}
			default: {
				return sha64.toBase64(wa);
			}
		}
	};
	return SHA512;
});
