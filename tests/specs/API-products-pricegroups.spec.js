/** @format */

/**
 * OpenAPI tests
 *
 * @group openapi
 */

// Import test packages
import axios from "axios";
import http from "axios/lib/adapters/http";
import jestOpenAPI from "jest-openapi";
import { StatusCodes } from "http-status-codes";
import { create_database, drop_database } from "./database";

// Load an OpenAPI file (YAML or JSON) into this plugin
jestOpenAPI(process.env.PWD + "/openapi/API.yaml");

// Set API version to use
const api = "erp/api/v0";

// Access to the database test user
const id = [...Array(6)].map(() => Math.random().toString(12)[2]).join("");
const username = `Jest${id}`;
const password = "Tester";
const company = `lsmb_test_api_${id}`;
const server = process.env.LSMB_BASE_URL;

let headers = {};

// For all tests
beforeAll(() => {
    axios.defaults.adapter = http;
    create_database(username, password, company);
});

afterAll(() => {
    drop_database(company);
});

// Log in before each test
beforeEach(async () => {
    let r = await axios.post(
        server + "/login.pl?action=authenticate&company=" + encodeURI(company),
        {
            company: company,
            password: password,
            login: username
        },
        {
            headers: {
                "X-Requested-With": "XMLHttpRequest",
                "Content-Type": "application/json"
            }
        }
    );
    if (r.status === StatusCodes.OK) {
        headers = {
            cookie: r.headers["set-cookie"],
            referer: server + "/" + r.data.target,
            authorization: "Basic " + btoa(username + ":" + password)
        };
    }
});
// Log out after each test
afterEach(async () => {
    let r = await axios.get(server + "/login.pl?action=logout&target=_top");
    if (r.status === StatusCodes.OK) {
        headers = {};
    }
});

// Product/Pricegroups tests
describe("Retrieving all products/pricegroups", () => {
    it("GET /products/pricegroups should satisfy OpenAPI spec", async () => {
        // Get an HTTP response from your server
        let res = await axios.get(
            server + "/" + api + "/products/pricegroups",
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();
    });
});

describe("Retrieving all products/pricegroups with old syntax should fail", () => {
    it("GET /products/pricegroups/ should fail", async () => {
        await expect(
            axios.get(server + "/" + api + "/products/pricegroups/", {
                headers: headers
            })
        ).rejects.toThrow("Request failed with status code " + StatusCodes.BAD_REQUEST);
    });
});

describe("Retrieve non-existant Pricegroup1", () => {
    it("GET /products/pricegroups/nv should not retrieve Pricegroup1", async () => {
        await expect(
            axios.get(server + "/" + api + "/products/pricegroups/1", {
                headers: headers
            })
        ).rejects.toThrow("Request failed with status code " + StatusCodes.NOT_FOUND);
    });
});

describe("Adding the new Price Group", () => {
    it("POST /products/pricegroups/Pricegroup1 should allow adding Pricegroup1", async () => {
        let res = await axios.post(
            server + "/" + api + "/products/pricegroups",
            {
                description: "Pricegroup1"
            },
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.CREATED);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Pricegroup");
    });
});

describe("Modifying the new Price Group", () => {
    it("PUT /products/pricegroups/Pricegroup1 should allow updating Pricegroup1", async () => {
        let res = await axios.get(
            server + "/" + api + "/products/pricegroups/1",
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.put(
            server + "/" + api + "/products/pricegroups/1",
            {
                id: 1,
                description: "PriceGroup1"
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Pricegroup");
    });
});

/*
 * Not implemented yet
describe("Updating the new Pricegroup1", () => {
    it("PATCH /products/pricegroups/nv should allow updating Pricegroup1", async () => {
        let res = await axios.get(server + "/" + api + "/products/pricegroups/PriceGroup1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.patch(
            server + "/" + api + "/products/pricegroups/nv",
            {
                description: "Pricegroup1"
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Pricegroup");
    });
});
*/

describe("Not removing the new Price Group", () => {
    it("DELETE /products/pricegroups/PriceGroup1 should allow deleting Pricegroup1", async () => {
        let res = await axios.get(
            server + "/" + api + "/products/pricegroups/1",
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();

        await expect(
            axios.delete(server + "/" + api + "/products/pricegroups/1", {
                headers: { ...headers, "If-Match": res.headers.etag }
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.FORBIDDEN
        );
    });
});
