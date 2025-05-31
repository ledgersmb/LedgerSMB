/** @format */

export async function promisify(dojoThenable) {
    return await new Promise((resolve, reject) => {
        dojoThenable.then(
            (value) => {
                let rv = value;
                if (value && typeof value.then === "function") {
                    if (
                        (value.isResolved && value.isResolved()) ||
                        (value.isFulfilled && value.isFulfilled())
                    ) {
                        if (Object.hasOwn(value, "then")) {
                            // 'un-thennable', to prevent infinite loop
                            delete value.then;
                        }
                    } else {
                        rv = promisify(value);
                    }
                }
                resolve(rv);
            },
            (err) => {
                reject(err);
            }
        );
    });
}
