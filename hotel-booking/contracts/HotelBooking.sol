// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract HotelBooking {
    // 방(Room)을 나타내는 구조체
    struct Room {
        uint id;          // 방의 고유 식별자
        string name;      // 방 이름
        uint price;       // 방 가격 (Wei 단위)
        bool isBooked;    // 방 예약 여부
    }

    // 예약(Booking)을 나타내는 구조체
    struct Booking {
        address customer;     // 방을 예약한 고객의 주소
        uint roomId;          // 예약한 방의 ID
        uint checkInDate;     // 체크인 날짜 (타임스탬프)
        uint checkOutDate;    // 체크아웃 날짜 (타임스탬프)
        uint bookingTime;     // 예약한 시간 (타임스탬프)
        bool isCancelled;     // 예약 취소 여부
    }

    address public owner;           // 계약 소유자
    Room[] public rooms;            // 모든 방들의 배열
    Booking[] public bookings;      // 모든 예약들의 배열

    // 방 ID와 해당 예약 정보를 매핑
    mapping(uint => Booking) public roomBookings;

    // 방이 예약되었을 때 발생하는 이벤트
    event RoomBooked(uint roomId, address customer, uint checkInDate, uint checkOutDate);

    // 예약이 취소되었을 때 발생하는 이벤트
    event BookingCancelled(uint bookingId, address customer, uint refundAmount);

    // 생성자에서 계약 배포자를 소유자로 설정
    constructor() {
        owner = msg.sender;
    }

    // 소유자만 함수에 접근할 수 있도록 하는 수정자
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // 새로운 방을 추가하는 함수, 소유자만 호출 가능
    function addRoom(string memory _name, uint _price) public onlyOwner {
        uint roomId = rooms.length; // 새로운 방 ID는 현재 방 배열의 길이
        rooms.push(Room(roomId, _name, _price, false)); // 새로운 방을 배열에 추가
    }

    // 방을 예약하는 함수
    function bookRoom(uint _roomId, uint _checkInDate, uint _checkOutDate) public payable {
        require(_roomId < rooms.length, "Invalid room id"); // 방 ID가 유효한지 확인
        require(!rooms[_roomId].isBooked, "Room is already booked"); // 방이 이미 예약되어 있지 않은지 확인
        require(msg.value == rooms[_roomId].price, "Incorrect Ether sent"); // 정확한 이더를 전송했는지 확인

        rooms[_roomId].isBooked = true; // 방을 예약된 상태로 표시
        uint bookingId = bookings.length; // 새로운 예약 ID는 현재 예약 배열의 길이
        bookings.push(Booking(msg.sender, _roomId, _checkInDate, _checkOutDate, block.timestamp, false)); // 새로운 예약을 배열에 추가
        roomBookings[_roomId] = bookings[bookingId]; // 방 ID를 예약 정보와 매핑

        emit RoomBooked(_roomId, msg.sender, _checkInDate, _checkOutDate); // RoomBooked 이벤트 발생
    }

    // 예약을 취소하는 함수
    function cancelBooking(uint _roomId) public {
        Booking storage booking = roomBookings[_roomId]; // 방의 예약 정보를 가져옴
        require(booking.customer == msg.sender, "Only the customer can cancel the booking"); // 예약한 고객만 취소할 수 있는지 확인
        require(!booking.isCancelled, "Booking is already cancelled"); // 예약이 이미 취소되지 않았는지 확인

        uint refundAmount = calculateRefund(booking.bookingTime, booking.roomId); // 환불 금액 계산
        booking.isCancelled = true; // 예약을 취소된 상태로 표시
        rooms[_roomId].isBooked = false; // 방을 예약되지 않은 상태로 표시

        payable(msg.sender).transfer(refundAmount); // 고객에게 계산된 금액을 환불
        emit BookingCancelled(_roomId, msg.sender, refundAmount); // BookingCancelled 이벤트 발생
    }

    // 경과 시간에 따른 환불 금액을 계산하는 내부 함수
    function calculateRefund(uint bookingTime, uint roomId) internal view returns (uint) {
        uint elapsed = block.timestamp - bookingTime; // 예약 후 경과 시간 계산
        uint price = rooms[roomId].price; // 방 가격 가져오기

        // 경과 시간에 따른 환불 금액 계산
        if (elapsed < 1 minutes) {
            return price * 100 / 100; // 1분 이내 취소 시 100% 환불
        } else if (elapsed < 2 minutes) {
            return price * 90 / 100; // 2분 이내 취소 시 90% 환불
        } else if (elapsed < 3 minutes) {
            return price * 80 / 100; // 3분 이내 취소 시 80% 환불
        } else if (elapsed < 4 minutes) {
            return price * 70 / 100; // 4분 이내 취소 시 70% 환불
        } else if (elapsed < 5 minutes) {
            return price * 60 / 100; // 5분 이내 취소 시 60% 환불
        } else {
            return 0; // 5분 이후 취소 시 환불 불가
        }
    }

    // 모든 방 정보를 가져오는 함수
    function getRooms() public view returns (Room[] memory) {
        return rooms; // 방 배열 반환
    }

    // 모든 예약 정보를 가져오는 함수
    function getBookings() public view returns (Booking[] memory) {
        return bookings; // 예약 배열 반환
    }
}
