/* eslint-disable camelcase */
// Import test packages
import { spawnSync } from "child_process";

// Access to the database test user

const pg_user = process.env.PGUSER ? process.env.PGUSER : "postgres";
const pg_host = process.env.PGHOST ? process.env.PGHOST : "localhost";

export function create_database(username, password, company) {
    let cmd = spawnSync(
        "./bin/ledgersmb-admin",
        ["create", `${pg_user}@${pg_host}/${company}#xyz`],
        {
            cwd: process.env.PWD
        }
    );
    if (cmd.status !== 0) {
        throw new Error(cmd.stderr.toString());
    }
    if (cmd.error) {
        if (typeof cmd.error === "string") {
            cmd.error = new Error(cmd.error);
        }
        throw cmd.error;
    }
    cmd = spawnSync(
        "./bin/ledgersmb-admin",
        [
            "user",
            "create",
            `${pg_user}@${pg_host}/${company}#xyz`,
            `--username=${username}`,
            `--password=${password}`,
            "--employeenumber=1",
            "--country=Canada",
            `--first_name=${username}`,
            `--last_name=${password}`,
            "--permission='Full Permissions'"
        ],
        {
            cwd: process.env.PWD
        }
    );
    if (cmd.status !== 0) {
        throw new Error(cmd.stderr.toString());
    }
    if (cmd.error) {
        if (typeof cmd.error === "string") {
            cmd.error = new Error(cmd.error);
        }
        throw cmd.error;
    }
    // Make sure API definition is current
    /*
        cmd = spawnSync("./utils/devel/rebuild_api.sh", [], {
            cwd: process.env.PWD
        });
        if (cmd.status !== 0) {
            throw new Error(cmd.stderr.toString());
        }
        if (cmd.error) {
            if (typeof cmd.error === "string") {
                cmd.error = new Error(cmd.error);
            }
            throw cmd.error;
        }
    */
}

export function drop_database(company) {
    let cmd = spawnSync("dropdb", [company]);
    if (cmd.status !== 0) {
        throw new Error(cmd.stderr.toString());
    }
    if (cmd.error) {
        if (typeof cmd.error === "string") {
            cmd.error = new Error(cmd.error);
        }
        throw cmd.error;
    }
}
