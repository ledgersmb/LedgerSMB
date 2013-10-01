define("dojox/encoding/digests/SHA224", ["./_sha-32"], function(sha32){
	//	The 224-bit implementation of SHA-2
	var hash = [
		0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939,
		0xffc00b31, 0x68581511, 0x64f98fa7, 0xbefa4fa4
	];

	var SHA224 = function(/* String */data, /* sha32.outputTypes? */outputType){
		var out = outputType || sha32.outputTypes.Base64;
		data = sha32.stringToUtf8(data);
		var wa = sha32.digest(sha32.toWord(data), data.length * 8, hash, 224);
		switch(out){
			case sha32.outputTypes.Raw: {
				return wa;
			}
			case sha32.outputTypes.Hex: {
				return sha32.toHex(wa);
			}
			case sha32.outputTypes.String: {
				return sha32._toString(wa);
			}
			default: {
				return sha32.toBase64(wa);
			}
		}
	};

	SHA224._hmac = function(/* String */data, /* String */key, /* sha32.outputTypes? */outputType){
		var out = outputType || sha32.outputTypes.Base64;
		data = sha32.stringToUtf8(data);
		key = sha32.stringToUtf8(key);

		//	prepare the key
		var wa = sha32.toWord(key);
		if(wa.length > 16){
			wa = sha32.digest(wa, key.length * 8, hash, 224);
		}

		//	set up the pads
		var ipad = new Array(16), opad = new Array(16);
		for(var i=0; i<16; i++){
			ipad[i] = wa[i] ^ 0x36363636;
			opad[i] = wa[i] ^ 0x5c5c5c5c;
		}

		//	make the final digest
		var r1 = sha32.digest(ipad.concat(sha32.toWord(data)), 512 + data.length * 8, hash, 224);
		var r2 = sha32.digest(opad.concat(r1), 512 + 160, hash, 224);

		//	return the output.
		switch(out){
			case sha32.outputTypes.Raw: {
				return wa;
			}
			case sha32.outputTypes.Hex: {
				return sha32.toHex(wa);
			}
			case sha32.outputTypes.String: {
				return sha32._toString(wa);
			}
			default: {
				return sha32.toBase64(wa);
			}
		}
	};

	return SHA224;
});
