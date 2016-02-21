define("dojox/encoding/digests/SHA384", ["./_sha-64"], function(sha64){
	//	The 384-bit implementation of SHA-2
	
	//	Note that for 64-bit hashes, we're actually doing high-order, low-order, high-order, low-order.
	//	The 64-bit functions will assemble them into actual 64-bit "words".
	var hash = [
		0xcbbb9d5d, 0xc1059ed8, 0x629a292a, 0x367cd507, 0x9159015a, 0x3070dd17, 0x152fecd8, 0xf70e5939,
		0x67332667, 0xffc00b31, 0x8eb44a87, 0x68581511, 0xdb0c2e0d, 0x64f98fa7, 0x47b5481d, 0xbefa4fa4
	];

	//	the exported function
	var SHA384 = function(/* String */data, /* sha64.outputTypes? */outputType){
		var out = outputType || sha64.outputTypes.Base64;
		data = sha64.stringToUtf8(data);
		var wa = sha64.digest(sha64.toWord(data), data.length * 8, hash, 384);
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
	SHA384._hmac = function(/* string */data, /* string */key, /* sha64.outputTypes? */outputType){
		var out = outputType || sha64.outputTypes.Base64;
		data = sha64.stringToUtf8(data);
		key = sha64.stringToUtf8(key);

		//	prepare the key
		var wa = sha64.toWord(key);
		if(wa.length > 16){
			wa = sha64.digest(wa, key.length * 8, hash, 384);
		}

		//	set up the pads
		var ipad = new Array(16), opad = new Array(16);
		for(var i=0; i<16; i++){
			ipad[i] = wa[i] ^ 0x36363636;
			opad[i] = wa[i] ^ 0x5c5c5c5c;
		}

		//	make the final digest
		var r1 = sha64.digest(ipad.concat(sha64.toWord(data)), 512 + data.length * 8, hash, 384);
		var r2 = sha64.digest(opad.concat(r1), 512 + 160, hash, 384);

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

	return SHA384;
});
