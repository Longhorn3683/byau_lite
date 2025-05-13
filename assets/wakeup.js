(function() {
    'use strict';

    function sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    var downloadButton = document.createElement("input");
    downloadButton.type = "button";
    downloadButton.value = "导出课表";
    downloadButton.style = "margin-top: 5px;margin-bottom: 5px;";
    downloadButton.className = "button el-button";

    var tutorial = document.createElement("div");
    tutorial.innerHTML = '若未弹出保存课表提示，请检查“上课班级”是否已正确填写。确保正确后，点击“查询”并点击“导出课表”';

    var form1 = document.getElementById("Form1");
    form1.after(downloadButton);
    form1.after(tutorial);

    downloadButton.onclick = async function () {
        var data = [["课程名称", "星期", "开始节数", "结束节数", "老师", "地点", "周数"]];
        var iframeWindow = window.document.getElementById("fcenter").contentWindow;
        cell(iframeWindow.document.getElementsByTagName("td"));
        function cell(array){
            for(var i=44; i<86; i++) {
                course(array[i].getElementsByClassName("kbcontent1"));
                function course(array2){
                    for(var j=0; j<array2.length; j++) {
                        let text = array2[j].innerText;
                        let result = text.replace(array[43].innerText, "").replace("\n\n", "\n");
                        const myArray = result.split("\n");
                        let name = myArray[0];
                        let day = (Math.floor((i-44)/6))+1;
                        let start = (((i-44)%6)+1)*2-1;
                        let end = (((i-44)%6)+1)*2;
                        let teacher = myArray[1].replace(" ", "").replace(/\(.*\)/, "");
                        let week = myArray[1].match(/(?<=\()(.+?)(?=\))/g);
                        let place = myArray[2];
                        data = data.concat([[name, day, start, end, teacher, place, week[0].replace("周", "").replace(",", "、")]]);
                    }
                };
            }
        };
        let csvStr = await '';
        for(var i=0; i<data.length; i++) {
            csvStr = csvStr + data[i] + ' ';
        }
        console.log(csvStr);
    }

    buttons(document.getElementsByClassName("button el-button"));
    async function buttons(array){
        for(var i=0; i<array.length; i++) {
            await array[i].click();
            await sleep(1000);
        }
    };

})();