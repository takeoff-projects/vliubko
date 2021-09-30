import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.0.2/firebase-app.js'
import { getFirestore, collection, doc, query, where, onSnapshot, addDoc, deleteDoc } from 'https://www.gstatic.com/firebasejs/9.0.2/firebase-firestore.js'

var GOOGLE_PROJECT_ID = "roi-takeoff-user77"
var FIREBASE_API_KEY = "AIzaSyA-QK9A8ZlxVb4fML8SrVgs4JJv2RGgXcA"
const OMS_LITE_API_API_GATEWAY = "https://oms-lite-964bmf9f.uc.gateway.dev"
const OMS_LITE_API_CLOUD_RUN = "https://oms-lite-r62e7tzm4a-uc.a.run.app"

const firebaseConfig = {
    apiKey: FIREBASE_API_KEY,
    authDomain: GOOGLE_PROJECT_ID + ".firebaseapp.com",
    projectId: GOOGLE_PROJECT_ID
};

const app = initializeApp(firebaseConfig);
const firebase_db = getFirestore(app);

const q = query(collection(firebase_db, "pickermans"));
const unsubscribe = onSnapshot(q, (querySnapshot) => {
  const pickermans = [];
  $('.pickers').empty();
  querySnapshot.forEach((doc) => {
    // start of debug
    var pickerman = `\nid: ${doc.id}, name: ${doc.data().name}, status: ${doc.data().status}`
    if (doc.data().order) {
      pickerman += `, order: ${doc.data().order}`
    }
    pickermans.push(pickerman);
    // end of debug

    addNewPickermanDiv(doc.id, doc.data().name, doc.data().status, doc.data().order);
  });
  console.log("Current pickermans: ", pickermans.join(""));
  // update isotope grid after changes
  isotopeGrid.isotope('reloadItems')
  isotopeGrid.isotope({ sortBy: 'status' });
});

function addNewPickermanDiv(id, name, status, orderID) {
  var PickermanDiv = `
  <!-- Picker card start-->
  <div class="card" style="width: 18rem;" id="${id}" picker-name="${name}" picking-status="${status}">

    <div class="card-body">
      <div class="row">
        <div class="col-9">
          <h5 class="card-title picker-name">${name}</h5>
        </div>
        <div class="col-sm">
          <img class="img-thumbnail" style="width: 4rem;" src="https://avatars.githubusercontent.com/u/7632467?s=96&v=4" alt="Card image cap">
        </div>
      </div>

      <div class="progress">`;

      if (status == "picking") {
        PickermanDiv += '<div class="progress-bar progress-bar-striped bg-success" role="progressbar" style="width: 50%" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100"></div></div>'
      } else {
        PickermanDiv += '<div class="progress-bar bg-info" role="progressbar" style="width: 100%" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100"></div></div>';
      }

      PickermanDiv += `
      <p class="card-text picking-status">
      <b>Status:</b> ${status}
      </p>`;

      if (orderID) {
        PickermanDiv += `<p class="card-text"><b>Order assigned:</b> ${orderID}</p>`
      }

      PickermanDiv +=
      `
      <div class="row justify-content-between">
        <div class="dropdown">
          <button class="btn btn-secondary dropdown-toggle" type="button" id="dropdownMenuButton" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
            Assign the order
          </button>
          <div class="dropdown-menu" aria-labelledby="dropdownMenuButton">
            <a class="dropdown-item" href="#">123</a>
            <a class="dropdown-item" href="#">456</a>
            <a class="dropdown-item" href="#">789</a>
          </div>
        </div>
        <div>
        <button type="button" class="btn btn-outline-danger btn-sm" data-toggle="modal" data-target="#deletePickerman-${id}" id="${id}" picker-name="${name}">Delete</button>
        </div>
      </div>
      <!-- Modal -->
      <div class="modal fade" id="deletePickerman-${id}" tabindex="-1" role="dialog" aria-labelledby="deletePickermanLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="deletePickermanLabel">Delete pickerman</h5>
              <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
            <div class="modal-body">
              Are you sure you want to delete <b>${name}</b>?
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
              <button type="button" class="btn btn-primary btn-danger btn-delete-picker" id="${id}" picker-name="${name}" data-dismiss="modal">Yes, delete</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
`;

  $('.pickers').append(PickermanDiv)
}

var isotopeGrid = $('.pickers').isotope({
  layoutMode: 'fitRows',
  getSortData: {
    name: '.picker-name',
    status: '[picking-status]'
  }
});


async function getOrders(url) {
  try {
    const response = await axios.get(url+'/api/v1/orders');
    console.log(response);
  } catch (error) {
    console.error(error);
  }
}

$(document).ready(function() {
  $(document).on('submit', '#add-new-picker', function() {
    var picker_name = $('#inputPickerName').val();
    $('#inputPickerName').val("");

    addDoc(collection(firebase_db, "pickermans"), {
      name: picker_name,
      status: "idle"
    });

    var submit = $("#btn-add-new-picker").html(`${picker_name} was saved!`).prop('class', 'btn btn-primary btn-success'); //Creating closure for setTimeout function. 
    setTimeout(function() {
      $(submit).html('Submit').prop('class', 'btn btn-primary')
    }, 1500);

    return false;
   });

  // sort items on button click
  $(document).on('click', '.btn-delete-picker', function() {
    const id = $(this).attr("id")
    console.log("Deleting the picker with id", id)
    deleteDoc(doc(firebase_db, "pickermans", id));
    
    // hide modal things
    $("#"+`deletePickerman-${id}`).modal('toggle');
    $(".modal-backdrop").remove();
  });

  getOrders(OMS_LITE_API_API_GATEWAY);
  getOrders(OMS_LITE_API_CLOUD_RUN);
  
  isotopeGrid.isotope('reloadItems')
});
