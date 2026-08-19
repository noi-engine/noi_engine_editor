.pragma library

function toUrl(path){
    if (!path) return "";
    const str = path.toString();
    return str.startsWith("file://") ? str : "file://" + str;
}
