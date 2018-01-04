var fs = require('fs');

var contents = JSON.parse(fs.readFileSync('export.json', 'utf-8'));

const groupID = "abc123";

const groups = {
    "hamptons": {
        "secret": "whitehouse",
        "groupID": groupID
    }
}

const userIds =
    Object.keys(contents)
        .filter(it => it != "users");

const hamptons =
    userIds.reduce( (acc, userId) => {
        let currData = contents[userId];
        let myPresents = Object.assign({}, currData.presents, {name: currData.meta.name});
        acc.users[userId] = currData.meta;
        acc.presents[userId] = myPresents;
        return acc;
    }, {users: {}, presents: {}})

let res = {};
res["groups"] = groups;
res[groupID] = hamptons

fs.writeFileSync('newdb.json', JSON.stringify(res));
