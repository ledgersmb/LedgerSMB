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
const id = Math.random().toString(36).substr(2, 6);

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

// Business Types tests
describe("Retrieving all Business Types", () => {
    it("GET /contacts/business-types should satisfy OpenAPI spec", async () => {
        // Get an HTTP response from your server
        let res = await axios.get(
            server + "/" + api + "/contacts/business-types",
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();
    });
});

describe("Retrieving all Business Types with old syntax should fail", () => {
    it("GET /contacts/business-types/ should fail", async () => {
        await expect(
            axios.get(server + "/" + api + "/contacts/business-types/", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.BAD_REQUEST
        );
    });
});

describe("Retrieve non-existant Business Type", () => {
    it("GET /contacts/business-types/1 should not retrieve our Business Types", async () => {
        await expect(
            axios.get(server + "/" + api + "/contacts/business-types/1", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.NOT_FOUND
        );
    });
});

describe("Adding the IT Business Types", () => {
    it("POST /contacts/business-types/1 should allow adding Business Type", async () => {
        let res = await axios.post(
            server + "/" + api + "/contacts/business-types",
            {
                description: "Big customer",
                discount: 0.05
            },
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.CREATED);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("NewBusinessType");
    });
});

describe("Modifying the new Business Type", () => {
    it("PUT /contacts/business-types/1 should allow updating Business Type", async () => {
        let res = await axios.get(
            server + "/" + api + "/contacts/business-types/1",
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.put(
            server + "/" + api + "/contacts/business-types/1",
            {
                id: 1,
                description: "Bigger customer",
                discount: "0.1"
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("BusinessType");
    });
});

/*
 * Not implemented yet
describe("Updating the new Business Type", () => {
    it("PATCH /contacts/business-types/1 should allow updating IT Business Types", async () => {
        let res = await axios.get(server + "/" + api + "/contacts/business-types/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.patch(
            server + "/" + api + "/contacts/business-types/1",
            {
                id: "1",
                description: "Navaho"
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Business Types");
    });
});
*/

describe("Not removing the new IT Business Types", () => {
    it("DELETE /contacts/business-types/1 should not allow deleting Business Type", async () => {
        let res = await axios.get(
            server + "/" + api + "/contacts/business-types/1",
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();

        await expect(
            axios.delete(server + "/" + api + "/contacts/business-types/1", {
                headers: { ...headers, "If-Match": res.headers.etag }
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.FORBIDDEN
        );
    });
});
