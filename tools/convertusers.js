var fs = require('fs');

var contents = JSON.parse(fs.readFileSync('users.json', 'utf-8'));

var target =
    contents.users.reduce( (acc, item) => {
        acc[item.email] = true;
        return acc;
    }, {})

fs.writeFileSync('target.json', JSON.stringify(target));
