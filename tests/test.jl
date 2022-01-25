
int main() {


    int x = 0;

    while(1) {
        printInt(-1);
        x = readInt();
        if(x == 0) {
            return 0;
        }
        printInt(1000 * x);
    }

    
    return 0;
}