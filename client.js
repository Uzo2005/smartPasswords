const exclusionBtn = document.getElementById("addExclusionRule");
const inclusionBtn = document.getElementById("addInclusionRule");
const passwordDisplay = document.getElementById("passwordDisplay");
const exclusionRuleBox = document.getElementById("exclusionRules");
const inclusionRuleBox = document.getElementById("inclusionRules");
const rulesForm = document.getElementById("passwordRulesForm");
const formSubmitBtn = document.getElementById("formSubmitter");

exclusionBtn.addEventListener("click", (e) => {
  e.preventDefault();
  const newRuleBox = document.createElement("div");
  const newRuleBoxLabel = document.createElement("label");
  const newRuleBoxInput = document.createElement("input");
  newRuleBox.classList.add(
    ..."bg-red-300 h-[50px] w-[90%] flex items-center gap-3".split(" ")
  );
  newRuleBoxLabel.classList.add(
    ..."font-bold text-sm h-full w-[150px] flex items-center justify-center".split(
      " "
    )
  );
  newRuleBoxLabel.setAttribute("for", "exclusionRule");
  newRuleBoxLabel.textContent = "Must Not Contain";
  newRuleBoxInput.classList.add(
    ..."h-full text-base w-full bg-transparent placeholder:text-black placeholder:text-opacity-100 font-bold text-black".split(
      " "
    )
  );
  newRuleBoxInput.setAttribute("type", "text");
  newRuleBoxInput.setAttribute("placeholder", "......");
  newRuleBoxInput.setAttribute("name", "exclusionRule");
  newRuleBox.appendChild(newRuleBoxLabel);
  newRuleBox.appendChild(newRuleBoxInput);

  exclusionRuleBox.insertBefore(newRuleBox, exclusionRuleBox.lastElementChild);
});

inclusionBtn.addEventListener("click", (e) => {
  e.preventDefault();
  const newRuleBox = document.createElement("div");
  const newRuleBoxLabel = document.createElement("label");
  const newRuleBoxInput = document.createElement("input");
  newRuleBox.classList.add(
    ..."bg-green-300 h-[50px] w-[90%] flex items-center gap-3".split(" ")
  );
  newRuleBoxLabel.classList.add(
    ..."font-bold text-sm h-full w-[150px] flex items-center justify-center".split(
      " "
    )
  );
  newRuleBoxLabel.setAttribute("for", "inclusionRule");
  newRuleBoxLabel.textContent = "Must Contain";
  newRuleBoxInput.classList.add(
    ..."h-full text-base w-full bg-transparent placeholder:text-black placeholder:text-opacity-100 font-bold text-black".split(
      " "
    )
  );
  newRuleBoxInput.setAttribute("type", "text");
  newRuleBoxInput.setAttribute("placeholder", "......");
  newRuleBoxInput.setAttribute("name", "inclusionRule");
  newRuleBox.appendChild(newRuleBoxLabel);
  newRuleBox.appendChild(newRuleBoxInput);

  inclusionRuleBox.insertBefore(newRuleBox, inclusionRuleBox.lastElementChild);
});

rulesForm.onsubmit = (e) => {
  e.preventDefault();
  passwordDisplay.classList.add("animate-pulse");
  passwordDisplay.classList.add("animate-bounce");
  formSubmitBtn.setAttribute("disabled", true);
  const formData = new FormData(rulesForm);
  const jsonData = {};

  formData.forEach((value, key) => {
    if (key == "inclusionRule" || key == "exclusionRule") {
      if (!jsonData[key]) {
        jsonData[key] = [];
      }
      jsonData[key].push(value);
    } else {
      jsonData[key] = value;
    }
  });

  fetch("/generatePassword", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(jsonData),
  })
    .then((response) => {
      passwordDisplay.classList.remove("animate-pulse");
      passwordDisplay.classList.remove("animate-bounce");
      formSubmitBtn.setAttribute("disabled", false);
      if (!response.ok) {
        throw new Error("Network response not ok");
      }
      return response.text();
    })
    .then((data) => {
      console.log("Data sent successfully, server sent us: ", data);
      passwordDisplay.innerHTML = data;
    })
    .catch((error) => {
      console.error("Error sending message to the server: ", error);
    });
};
