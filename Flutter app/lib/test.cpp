#include <iostream>
using namespace std;

string digitSum(string s, int k) {
        string tmp=s,ret;
        int sum=0;
        while(tmp.size()>k){
            for(int i=0;i<tmp.size();i++){
                sum += tmp[i]-'0';
                if(i%k==k-1 || i==tmp.size()-1){
                    ret +=to_string(sum);
                    sum=0;
                }
            }
            cout<<ret<<endl;
            tmp=ret;
            ret="";
        }
        return tmp;
    }

    bool istrue(string str){
        int a=0,b=0;
        for(int i=0;i<str.size();i++){
            if(str[i]>='a' && str[i]<='z'){
                a++;
            }else{
                b++;
            }
        }
        return a==b;
    }
    int countSubstring(string s)
    {
        // code here
        int cnt=0;
        for(int i=2;i<=s.size();i++){
            for(int j=0;j<=s.size()-i;j++){
                if(istrue(s.substr(j,i))) cnt++;
                cout<<s.substr(j,i)<<endl;
            }
        }
        return cnt;
    }

    int main(){
        string s = "WomensDAY";
        
        cout<<countSubstring(s);
        return 0;
    }
