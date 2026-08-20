.pragma library

function toUrl(path){
    if (!path) return "";
    const str = path.toString();
    return str.startsWith("file://") ? str : "file://" + str;
}

function toLocalPath(path) {
    if (!path) return "";
    let str = path.toString();

    if (str.startsWith("file://")) {
        str = str.substring(7);
    }

    if (str.startsWith("/") && str.length > 2 && str[2] === ':') {
        str = str.substring(1);
    }

    return decodeURIComponent(str);
}